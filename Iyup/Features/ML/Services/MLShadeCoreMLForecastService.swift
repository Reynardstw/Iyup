import Foundation
import CoreML

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
            case .shortLux: return "IyupShortLuxV2"
            case .shortTemp: return "IyupShortTempV2"
            case .shortOccupancy: return "IyupShortOccupancyV2"
            case .longLux: return "IyupLongLuxV2"
            case .longTemp: return "IyupLongTempV2"
            case .longOccupancy: return "IyupLongOccupancyV2"
            }
        }

        var manifestName: String {
            "iyup_features_\(rawValue)_v2"
        }

        var outputName: String {
            switch self {
            case .shortLux, .longLux: return "predicted_lux"
            case .shortTemp, .longTemp: return "predicted_temp"
            case .shortOccupancy, .longOccupancy: return "predicted_occupancy"
            }
        }

        var isLongHorizonModel: Bool {
            switch self {
            case .longLux, .longTemp, .longOccupancy:
                return true
            case .shortLux, .shortTemp, .shortOccupancy:
                return false
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

        self.bundle = bundle
        self.calendar = calendar
        self.sensorFeatureProvider = sensorFeatureProvider

        var manifests: [ModelKey: ModelManifest] = [:]
        for key in ModelKey.allCases {
            manifests[key] = try Self.loadManifest(for: key, bundle: bundle)
            let featureCount = manifests[key]?.features_ordered.count ?? 0
        }

        guard let firstMapping = manifests.values.first?.spot_mapping else {
            throw MLShadeForecastError.manifestNotFound
        }
        self.spotMapping = firstMapping

        var models: [ModelKey: LoadedModel] = [:]
        for key in ModelKey.allCases {
            let manifest = manifests[key]
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
        }
        self.loadedModels = models

        let loadedNames = models.keys.map { $0.modelName }.sorted().joined(separator: ", ")
    }

    func forecast(
        for shadowResult: ShadowIntervalResult,
        referenceDate: Date,
        debugRunID: String
    ) async throws -> [MLShadeEnvironmentForecastPoint] {

        guard !shadowResult.timeline.isEmpty else {
            throw MLShadeForecastError.emptyTimeline(shadowResult.spot.name)
        }

        guard let spotNumber = spotNumber(for: shadowResult.spot) else {
            throw MLShadeForecastError.spotMappingNotFound(shadowResult.spot.id)
        }

        let currentEntry = shadowResult.timeline[0]

        return try shadowResult.timeline.map { entry in
            let horizonMinutes = max(entry.sampleDate.timeIntervalSince(referenceDate) / 60.0, 0.0)
            let isShort = horizonMinutes <= 240.0

            let luxRaw = try predict(
                isShort ? .shortLux : .longLux,
                spot: shadowResult.spot,
                spotNumber: spotNumber,
                entry: entry,
                currentEntry: currentEntry,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            let temperatureRaw = try predict(
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

            let lux = sanitizeLux(luxRaw, entry: entry, debugRunID: debugRunID)
            let temperature = sanitizeTemperature(temperatureRaw, entry: entry, debugRunID: debugRunID)
            let occupancy = max(0.0, min(1.0, occupancyRaw))

            return MLShadeEnvironmentForecastPoint(
                sampleDate: entry.sampleDate,
                lux: lux,
                temperatureCelsius: temperature,

                occupancy: occupancy
            )
        }
    }

    private func spotNumber(for spot: ParkSpot) -> Int? {
        let modelSpotID = resolveModelSpotID(from: spot.id)

        if let exact = spotMapping[modelSpotID] {
            return exact
        }

        let normalizedSpotID = normalizeSpotID(modelSpotID)
        return spotMapping.first { key, _ in
            normalizeSpotID(key) == normalizedSpotID
        }?.value
    }

    private func resolveModelSpotID(from appSpotID: String) -> String {
        let normalized = appSpotID
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")

        let alias: [String: String] = [
            "bench1": "Spot_A",
            "bench2": "Spot_B",
            "bench3": "Spot_C",
            "bench4": "Spot_D",
            "bench5": "Spot_E",
            "spota": "Spot_A",
            "spotb": "Spot_B",
            "spotc": "Spot_C",
            "spotd": "Spot_D",
            "spote": "Spot_E",
        ]

        return alias[normalized] ?? appSpotID
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
            throw MLShadeForecastError.modelUnavailable(key.modelName)
        }

        var features = sensorFeatureProvider(spot, key.rawValue, entry.sampleDate)
        mergeAutomaticFeatures(
            into: &features,
            modelKey: key,
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
                throw MLShadeForecastError.missingFeature(featureName, model: key.rawValue)
            }
            dictionary[featureName] = MLFeatureValue(double: value)
        }

        for featureName in loaded.features {
            if let featureValue = dictionary[featureName] {
            }
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: dictionary)
        let output = try loaded.model.prediction(from: provider)

        if let value = output.featureValue(for: loaded.outputName) {
            return value.doubleValue
        }

        let available = Array(output.featureNames).sorted()
        throw MLShadeForecastError.invalidOutput(loaded.outputName, model: key.rawValue, available: available)
    }

    private func mergeAutomaticFeatures(
        into features: inout [String: Double],

        modelKey: ModelKey,
        spotNumber: Int,
        entry: ShadowTimelineEntry,
        currentEntry: ShadowTimelineEntry,
        referenceDate: Date
    ) {
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: entry.sampleDate)
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0

        let dayOfWeek = Double(((components.weekday ?? 1) + 5) % 7)
        let horizonMinutes = max(entry.sampleDate.timeIntervalSince(referenceDate) / 60.0, 0.0)
        let leadDays = max(1.0, min(7.0, ceil(entry.sampleDate.timeIntervalSince(referenceDate) / 86_400.0)))

        features["spot_num"] = Double(spotNumber)
        features["hour"] = hour
        features["day_of_week"] = dayOfWeek
        features["is_weekend"] = dayOfWeek >= 5 ? 1.0 : 0.0
        features["horizon"] = horizonMinutes
        features["lead_days"] = leadDays

        if modelKey.isLongHorizonModel {
            features["shadow_status"] = entry.isShaded ? 1.0 : 0.0
            features["sun_altitude"] = entry.sunPosition.altitudeDegrees
        } else {
            features["shadow_status"] = currentEntry.isShaded ? 1.0 : 0.0
            features["sun_altitude"] = currentEntry.sunPosition.altitudeDegrees
        }

        features["shadow_status_future"] = entry.isShaded ? 1.0 : 0.0
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
        let fallbackLux = fallbackLuxValue(isShaded: shadedNow, sunAltitudeDegrees: currentEntry.sunPosition.altitudeDegrees)
        let fallbackTemp = fallbackTemperatureValue(isShaded: shadedNow, sunAltitudeDegrees: currentEntry.sunPosition.altitudeDegrees)
        let fallbackOccupancy = shadedNow ? 0.18 : 0.12

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

    private func fallbackLuxValue(isShaded: Bool, sunAltitudeDegrees: Double) -> Double {
        let sunStrength = max(0.0, sin(sunAltitudeDegrees * .pi / 180.0))
        let openLux = 105_000.0 * pow(sunStrength, 1.15) * 0.78
        let shadedLux = max(600.0, openLux * 0.12 + 450.0)
        return max(0.0, isShaded ? shadedLux : openLux)
    }

    private func fallbackTemperatureValue(isShaded: Bool, sunAltitudeDegrees: Double) -> Double {
        let sunStrength = max(0.0, sin(sunAltitudeDegrees * .pi / 180.0))
        let base = 29.0 + 2.5 * sunStrength
        return isShaded ? max(25.0, base - 1.2) : min(36.0, base + 0.6)
    }

    private func sanitizeLux(
        _ value: Double,
        entry: ShadowTimelineEntry,
        debugRunID: String
    ) -> Double {
        guard value.isFinite else {
            let fallback = fallbackLuxValue(isShaded: entry.isShaded, sunAltitudeDegrees: entry.sunPosition.altitudeDegrees)
            return fallback
        }

        if value < 0.0 {
            return 0.0
        }

        return min(value, 120_000.0)
    }

    private func sanitizeTemperature(
        _ value: Double,
        entry: ShadowTimelineEntry,
        debugRunID: String
    ) -> Double {
        guard value.isFinite else {
            let fallback = fallbackTemperatureValue(isShaded: entry.isShaded, sunAltitudeDegrees: entry.sunPosition.altitudeDegrees)
            return fallback
        }

        if value < 15.0 || value > 45.0 {
            let fallback = fallbackTemperatureValue(isShaded: entry.isShaded, sunAltitudeDegrees: entry.sunPosition.altitudeDegrees)
            return fallback
        }

        return value
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
            subdirectories: [nil, "MLModels/Json", "Features/ML/Resources/Json"]
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
            subdirectories: [nil, "MLModels/Models", "Features/ML/Resources/Models"]
        ) {
            return try MLModel(contentsOf: compiledURL)
        }

        if let modelURL = resourceURL(
            bundle: bundle,
            name: name,
            extensionName: "mlmodel",
            subdirectories: [nil, "MLModels/Models", "Features/ML/Resources/Models"]
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
