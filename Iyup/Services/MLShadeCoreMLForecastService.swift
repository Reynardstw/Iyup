import Foundation
import CoreML

/// Core ML implementation for the ML shade add-on.
///
/// This version is aligned with the XGBoost export:
/// - Uses six individual `model_features_*_xgb.json` files.
/// - Uses `spot_num`, not `spot_id`, as model input.
/// - Loads the six `Model*.mlmodel` files.
/// - Keeps safe defaults for sensor/history values so initial integration does not crash.
final class MLShadeCoreMLForecastService: MLShadeEnvironmentForecastProviding, @unchecked Sendable {
    private enum ModelKey: String, CaseIterable, Sendable {
        case shortLux = "short_lux"
        case shortTemp = "short_temp"
        case shortOccupancy = "short_occupancy"
        case longLux = "long_lux"
        case longTemp = "long_temp"
        case longOccupancy = "long_occupancy"

        var modelName: String {
            switch self {
            case .shortLux: return "ModelShortLux"
            case .shortTemp: return "ModelShortTemp"
            case .shortOccupancy: return "ModelShortOccupancy"
            case .longLux: return "ModelLongLux"
            case .longTemp: return "ModelLongTemp"
            case .longOccupancy: return "ModelLongOccupancy"
            }
        }

        var manifestName: String {
            "model_features_\(rawValue)_xgb"
        }

        var outputName: String {
            switch self {
            case .shortLux, .longLux: return "predicted_lux"
            case .shortTemp, .longTemp: return "predicted_temp"
            case .shortOccupancy, .longOccupancy: return "predicted_occupancy"
            }
        }

        var defaultFeatures: [String] {
            switch self {
            case .shortLux:
                return [
                    "spot_num", "horizon", "hour", "day_of_week", "is_weekend",
                    "is_holiday", "shadow_status", "shadow_status_future",
                    "sun_altitude", "sun_altitude_future", "cloud_cover",
                    "cloud_forecast_future", "lux", "lux_lag_15m", "lux_lag_30m",
                    "lux_lag_60m", "lux_rollmean_30m", "lux_trend"
                ]
            case .shortTemp:
                return [
                    "spot_num", "horizon", "hour", "day_of_week", "is_weekend",
                    "is_holiday", "shadow_status", "shadow_status_future",
                    "sun_altitude", "sun_altitude_future", "cloud_cover",
                    "cloud_forecast_future", "temp", "temp_lag_15m", "temp_lag_30m",
                    "temp_lag_60m", "temp_rollmean_30m", "temp_trend", "lux"
                ]
            case .shortOccupancy:
                return [
                    "spot_num", "horizon", "hour", "day_of_week", "is_weekend",
                    "is_holiday", "shadow_status", "shadow_status_future",
                    "sun_altitude", "sun_altitude_future", "cloud_cover",
                    "cloud_forecast_future", "occupancy", "occupancy_lag_15m",
                    "occupancy_lag_30m", "occupancy_lag_60m", "occupancy_rollmean_30m",
                    "occupancy_trend", "temp", "lux"
                ]
            case .longLux, .longTemp, .longOccupancy:
                return [
                    "spot_num", "hour", "day_of_week", "is_weekend", "is_holiday",
                    "shadow_status", "sun_altitude", "cloud_forecast", "lead_days"
                ]
            }
        }
    }

    private struct ModelManifest: Decodable, Sendable {
        let coreml_file: String?
        let target: String
        let features_ordered: [String]
        let spot_mapping: [String: Int]
    }

    typealias SensorFeatureProvider = @Sendable (
        _ spot: ParkSpot,
        _ modelName: String,
        _ sampleDate: Date
    ) -> [String: Double]

    private struct LoadedModel: Sendable {
        let key: ModelKey
        let model: MLModel
        let features: [String]
        let outputName: String
    }

    private let bundle: Bundle
    private let calendar: Calendar
    private let sensorFeatureProvider: SensorFeatureProvider
    private let spotMapping: [String: Int]
    private let loadedModels: [ModelKey: LoadedModel]

    init(
        bundle: Bundle = .main,
        calendar: Calendar = .current,
        sensorFeatureProvider: @escaping SensorFeatureProvider = MLShadeCoreMLForecastService.defaultSensorFeatureProvider
    ) throws {
        print("🔎 [MLShade] Core ML forecast service init started")

        self.bundle = bundle
        self.calendar = calendar
        self.sensorFeatureProvider = sensorFeatureProvider

        var manifests: [ModelKey: ModelManifest] = [:]
        for key in ModelKey.allCases {
            print("📄 [MLShade] Loading manifest: \(key.manifestName).json")
            manifests[key] = try Self.loadManifest(for: key, bundle: bundle)
            let featureCount = manifests[key]?.features_ordered.count ?? 0
            print("✅ [MLShade] Loaded manifest: \(key.manifestName).json, features=\(featureCount)")
        }

        guard let firstMapping = manifests.values.first?.spot_mapping else {
            print("❌ [MLShade] No spot_mapping found in XGBoost manifests")
            throw MLShadeForecastError.manifestNotFound
        }
        self.spotMapping = firstMapping
        print("✅ [MLShade] Spot mapping loaded: \(firstMapping)")

        var models: [ModelKey: LoadedModel] = [:]
        for key in ModelKey.allCases {
            let manifest = manifests[key]
            print("🧠 [MLShade] Loading Core ML model: \(key.modelName)")
            let model = try Self.loadModel(named: key.modelName, bundle: bundle)
            let features = manifest?.features_ordered.isEmpty == false
                ? manifest!.features_ordered
                : key.defaultFeatures

            models[key] = LoadedModel(
                key: key,
                model: model,
                features: features,
                outputName: key.outputName
            )
            print("✅ [MLShade] Loaded model: \(key.modelName), output=\(key.outputName), featureCount=\(features.count)")
        }
        self.loadedModels = models

        let loadedNames = models.keys.map { $0.modelName }.sorted().joined(separator: ", ")
        print("✅ [MLShade] Core ML forecast service ready. Loaded models: \(loadedNames)")
    }

    func forecast(
        for shadowResult: ShadowIntervalResult,
        referenceDate: Date,
        debugRunID: String
    ) async throws -> [MLShadeEnvironmentForecastPoint] {
        print("🧠 [MLShade][\(debugRunID)] Core ML forecast called")
        print("🧠 [MLShade][\(debugRunID)] Spot: \(shadowResult.spot.id) - \(shadowResult.spot.name)")
        print("🧠 [MLShade][\(debugRunID)] Timeline count: \(shadowResult.timeline.count)")

        guard !shadowResult.timeline.isEmpty else {
            print("❌ [MLShade][\(debugRunID)] Empty timeline for spot: \(shadowResult.spot.name)")
            throw MLShadeForecastError.emptyTimeline(shadowResult.spot.name)
        }

        guard let spotNumber = spotNumber(for: shadowResult.spot) else {
            print("❌ [MLShade][\(debugRunID)] Spot mapping not found for: \(shadowResult.spot.id)")
            throw MLShadeForecastError.spotMappingNotFound(shadowResult.spot.id)
        }

        print("✅ [MLShade][\(debugRunID)] spot_num for \(shadowResult.spot.id): \(spotNumber)")

        let currentEntry = shadowResult.timeline[0]

        return try shadowResult.timeline.map { entry in
            let horizonMinutes = max(entry.sampleDate.timeIntervalSince(referenceDate) / 60.0, 0.0)
            let isShort = horizonMinutes <= 240.0

            print("🕒 [MLShade][\(debugRunID)] Forecast sample: spot=\(shadowResult.spot.id), date=\(entry.sampleDate), regime=\(isShort ? "short" : "long"), horizonMinutes=\(horizonMinutes)")

            let lux = try predict(
                isShort ? .shortLux : .longLux,
                spot: shadowResult.spot,
                spotNumber: spotNumber,
                entry: entry,
                currentEntry: currentEntry,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            let temperature = try predict(
                isShort ? .shortTemp : .longTemp,
                spot: shadowResult.spot,
                spotNumber: spotNumber,
                entry: entry,
                currentEntry: currentEntry,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            let occupancyRaw = try predict(
                isShort ? .shortOccupancy : .longOccupancy,
                spot: shadowResult.spot,
                spotNumber: spotNumber,
                entry: entry,
                currentEntry: currentEntry,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            print("✅ [MLShade][\(debugRunID)] Forecast sample output: spot=\(shadowResult.spot.id), lux=\(lux), temp=\(temperature), occupancyRaw=\(occupancyRaw)")

            return MLShadeEnvironmentForecastPoint(
                sampleDate: entry.sampleDate,
                lux: lux,
                temperatureCelsius: temperature,
                occupancy: max(0.0, min(1.0, occupancyRaw))
            )
        }
    }

    private func spotNumber(for spot: ParkSpot) -> Int? {
        if let exact = spotMapping[spot.id] {
            return exact
        }

        let normalizedSpotID = normalizeSpotID(spot.id)
        return spotMapping.first { key, _ in
            normalizeSpotID(key) == normalizedSpotID
        }?.value
    }

    private func predict(
        _ key: ModelKey,
        spot: ParkSpot,
        spotNumber: Int,
        entry: ShadowTimelineEntry,
        currentEntry: ShadowTimelineEntry,
        referenceDate: Date,
        debugRunID: String
    ) throws -> Double {
        guard let loaded = loadedModels[key] else {
            print("❌ [MLShade][\(debugRunID)] Model unavailable: \(key.modelName)")
            throw MLShadeForecastError.modelUnavailable(key.modelName)
        }

        print("🧠 [MLShade][\(debugRunID)] Predicting with Core ML model: \(key.modelName)")

        var features = sensorFeatureProvider(spot, key.rawValue, entry.sampleDate)
        mergeAutomaticFeatures(
            into: &features,
            spotNumber: spotNumber,
            entry: entry,
            currentEntry: currentEntry,
            referenceDate: referenceDate
        )
        mergeSafeSensorDefaults(into: &features, entry: entry, currentEntry: currentEntry)

        var dictionary: [String: MLFeatureValue] = [:]
        dictionary.reserveCapacity(loaded.features.count)

        for featureName in loaded.features {
            guard let value = features[featureName], value.isFinite else {
                print("❌ [MLShade][\(debugRunID)] Missing/invalid feature for \(key.modelName): \(featureName)")
                print("📦 [MLShade][\(debugRunID)] Available feature keys: \(features.keys.sorted())")
                throw MLShadeForecastError.missingFeature(featureName, model: key.rawValue)
            }
            dictionary[featureName] = MLFeatureValue(double: value)
        }

        print("📦 [MLShade][\(debugRunID)] \(key.modelName) input feature count: \(dictionary.count)")
        for featureName in loaded.features {
            if let featureValue = dictionary[featureName] {
                print("📦 [MLShade][\(debugRunID)] \(key.modelName).input[\(featureName)] = \(featureValue.doubleValue)")
            }
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: dictionary)
        let output = try loaded.model.prediction(from: provider)

        if let value = output.featureValue(for: loaded.outputName) {
            print("✅ [MLShade][\(debugRunID)] \(key.modelName).\(loaded.outputName) = \(value.doubleValue)")
            return value.doubleValue
        }

        let available = Array(output.featureNames).sorted()
        print("❌ [MLShade][\(debugRunID)] Output not found for \(key.modelName). Expected: \(loaded.outputName), available: \(available)")
        throw MLShadeForecastError.invalidOutput(loaded.outputName, model: key.rawValue, available: available)
    }

    private func mergeAutomaticFeatures(
        into features: inout [String: Double],
        spotNumber: Int,
        entry: ShadowTimelineEntry,
        currentEntry: ShadowTimelineEntry,
        referenceDate: Date
    ) {
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: entry.sampleDate)
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0

        // Calendar weekday: Sunday = 1. Convert to Python/pandas dayofweek: Monday = 0 ... Sunday = 6.
        let dayOfWeek = Double(((components.weekday ?? 1) + 5) % 7)
        let horizonMinutes = max(entry.sampleDate.timeIntervalSince(referenceDate) / 60.0, 0.0)
        let leadDays = max(1.0, min(7.0, ceil(entry.sampleDate.timeIntervalSince(referenceDate) / 86_400.0)))

        // XGBoost model input is `spot_num`, not `spot_id`.
        features["spot_num"] = Double(spotNumber)
        features["hour"] = hour
        features["day_of_week"] = dayOfWeek
        features["is_weekend"] = dayOfWeek >= 5 ? 1.0 : 0.0
        features["horizon"] = horizonMinutes
        features["lead_days"] = leadDays

        features["shadow_status"] = currentEntry.isShaded ? 1.0 : 0.0
        features["shadow_status_future"] = entry.isShaded ? 1.0 : 0.0
        features["sun_altitude"] = currentEntry.sunPosition.altitudeDegrees
        features["sun_altitude_future"] = entry.sunPosition.altitudeDegrees

        features["is_holiday"] = features["is_holiday"] ?? 0.0
        features["cloud_cover"] = features["cloud_cover"] ?? 0.30
        features["cloud_forecast"] = features["cloud_forecast"] ?? features["cloud_cover"] ?? 0.30
        features["cloud_forecast_future"] = features["cloud_forecast_future"] ?? features["cloud_forecast"] ?? 0.30
    }

    private func mergeSafeSensorDefaults(
        into features: inout [String: Double],
        entry: ShadowTimelineEntry,
        currentEntry: ShadowTimelineEntry
    ) {
        let shadedNow = currentEntry.isShaded
        let shadedFuture = entry.isShaded

        let fallbackLux = shadedNow ? 900.0 : 18_000.0
        let fallbackTemp = shadedNow ? 30.0 : 32.0
        let fallbackOccupancy = shadedFuture ? 0.45 : 0.25

        let lux = features["lux"] ?? fallbackLux
        let temp = features["temp"] ?? fallbackTemp
        let occupancy = features["occupancy"] ?? fallbackOccupancy

        features["lux"] = lux
        features["temp"] = temp
        features["occupancy"] = occupancy

        fillLagDefaults(prefix: "lux", currentValue: lux, into: &features)
        fillLagDefaults(prefix: "temp", currentValue: temp, into: &features)
        fillLagDefaults(prefix: "occupancy", currentValue: occupancy, into: &features)
    }

    private func fillLagDefaults(
        prefix: String,
        currentValue: Double,
        into features: inout [String: Double]
    ) {
        features["\(prefix)_lag_15m"] = features["\(prefix)_lag_15m"] ?? currentValue
        features["\(prefix)_lag_30m"] = features["\(prefix)_lag_30m"] ?? currentValue
        features["\(prefix)_lag_60m"] = features["\(prefix)_lag_60m"] ?? currentValue
        features["\(prefix)_rollmean_30m"] = features["\(prefix)_rollmean_30m"] ?? currentValue
        features["\(prefix)_trend"] = features["\(prefix)_trend"] ?? 0.0
    }

    private static func defaultSensorFeatureProvider(
        spot: ParkSpot,
        modelName: String,
        sampleDate: Date
    ) -> [String: Double] {
        [
            "is_holiday": 0.0,
            "cloud_cover": 0.30,
            "cloud_forecast": 0.30,
            "cloud_forecast_future": 0.30
        ]
    }

    private static func loadManifest(
        for key: ModelKey,
        bundle: Bundle
    ) throws -> ModelManifest {
        guard let url = resourceURL(
            bundle: bundle,
            name: key.manifestName,
            extensionName: "json",
            subdirectories: [nil, "MLModels/Json"]
        ) else {
            throw MLShadeForecastError.manifestNotFound
        }

        return try JSONDecoder().decode(
            ModelManifest.self,
            from: Data(contentsOf: url)
        )
    }

    private static func loadModel(
        named name: String,
        bundle: Bundle
    ) throws -> MLModel {
        if let compiledURL = resourceURL(
            bundle: bundle,
            name: name,
            extensionName: "mlmodelc",
            subdirectories: [nil, "MLModels/Models"]
        ) {
            return try MLModel(contentsOf: compiledURL)
        }

        if let modelURL = resourceURL(
            bundle: bundle,
            name: name,
            extensionName: "mlmodel",
            subdirectories: [nil, "MLModels/Models"]
        ) {
            let compiledURL = try MLModel.compileModel(at: modelURL)
            return try MLModel(contentsOf: compiledURL)
        }

        throw MLShadeForecastError.modelUnavailable(name)
    }

    private static func resourceURL(
        bundle: Bundle,
        name: String,
        extensionName: String,
        subdirectories: [String?]
    ) -> URL? {
        for subdirectory in subdirectories {
            if let url = bundle.url(
                forResource: name,
                withExtension: extensionName,
                subdirectory: subdirectory
            ) {
                return url
            }
        }
        return nil
    }

    private func normalizeSpotID(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }
}
