import Foundation
import CoreML

public enum ForecastTarget: String, CaseIterable, Sendable {
    case lux
    case temp
    case occupancy

    var outputFeatureName: String {
        "predicted_\(rawValue)"
    }
}

public struct EnvironmentForecastValues: Sendable {
    public let lux: Double
    public let temp: Double
    public let occupancy: Double

    public init(lux: Double, temp: Double, occupancy: Double) {
        self.lux = lux
        self.temp = temp
        self.occupancy = occupancy
    }
}

public enum CoreMLForecastServiceError: Error, LocalizedError {
    case modelNotFound(String)
    case missingFeature(String, modelName: String)
    case invalidOutput(expected: String, available: [String])
    case invalidManifest(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "Core ML model '\(name)' was not found in the app bundle. Check Target Membership."
        case .missingFeature(let feature, let modelName):
            return "Feature '\(feature)' is missing for model '\(modelName)'."
        case .invalidOutput(let expected, let available):
            return "Expected output '\(expected)' was not found. Available outputs: \(available.joined(separator: ", "))."
        case .invalidManifest(let name):
            return "Could not parse feature manifest '\(name).json'."
        }
    }
}

public final class CoreMLEnvironmentForecastService {
    private enum ModelKey: String, CaseIterable {
        case shortLux = "short_lux"
        case shortTemp = "short_temp"
        case shortOccupancy = "short_occupancy"
        case longLux = "long_lux"
        case longTemp = "long_temp"
        case longOccupancy = "long_occupancy"

        var mlModelName: String {
            switch self {
            case .shortLux: return "ModelShortLux"
            case .shortTemp: return "ModelShortTemp"
            case .shortOccupancy: return "ModelShortOccupancy"
            case .longLux: return "ModelLongLux"
            case .longTemp: return "ModelLongTemp"
            case .longOccupancy: return "ModelLongOccupancy"
            }
        }

        var jsonManifestName: String {
            "model_features_\(rawValue)_xgb"
        }

        var target: ForecastTarget {
            switch self {
            case .shortLux, .longLux: return .lux
            case .shortTemp, .longTemp: return .temp
            case .shortOccupancy, .longOccupancy: return .occupancy
            }
        }

        var fallbackFeatures: [String] {
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

    private struct ModelBundle {
        let key: ModelKey
        let model: MLModel
        let features: [String]
    }

    private let featureBuilder: ForecastFeatureBuilder
    private let models: [ModelKey: ModelBundle]

    public init(
        configuration: MLModelConfiguration = MLModelConfiguration(),
        featureBuilder: ForecastFeatureBuilder = ForecastFeatureBuilder()
    ) throws {
        self.featureBuilder = featureBuilder

        var loadedModels: [ModelKey: ModelBundle] = [:]
        for key in ModelKey.allCases {
            let model = try Self.loadModel(named: key.mlModelName, configuration: configuration)
            let features = Self.loadFeatureOrder(for: key)
            loadedModels[key] = ModelBundle(key: key, model: model, features: features)
        }
        self.models = loadedModels
    }

    /// Predicts short-term lux, temperature, and occupancy.
    /// Recommended horizons are the same as training: 15, 30, 60, 120, or 240 minutes.
    public func predictShort(
        snapshot: ForecastSensorSnapshot,
        history: ForecastHistory? = nil,
        horizonMinutes: Int
    ) throws -> EnvironmentForecastValues {
        let featurePool = try featureBuilder.makeShortFeaturePool(
            snapshot: snapshot,
            history: history,
            horizonMinutes: horizonMinutes
        )

        return EnvironmentForecastValues(
            lux: try predict(.shortLux, featurePool: featurePool),
            temp: try predict(.shortTemp, featurePool: featurePool),
            occupancy: try predict(.shortOccupancy, featurePool: featurePool)
        )
    }

    /// Predicts long-term lux, temperature, and occupancy.
    /// Recommended lead-days range follows training: 1...7.
    public func predictLong(
        snapshot: ForecastSensorSnapshot,
        leadDays: Int
    ) throws -> EnvironmentForecastValues {
        let clampedLeadDays = max(1, min(7, leadDays))
        let featurePool = try featureBuilder.makeLongFeaturePool(
            snapshot: snapshot,
            leadDays: clampedLeadDays
        )

        return EnvironmentForecastValues(
            lux: try predict(.longLux, featurePool: featurePool),
            temp: try predict(.longTemp, featurePool: featurePool),
            occupancy: try predict(.longOccupancy, featurePool: featurePool)
        )
    }

    private func predict(_ key: ModelKey, featurePool: [String: Double]) throws -> Double {
        guard let bundle = models[key] else {
            throw CoreMLForecastServiceError.modelNotFound(key.mlModelName)
        }

        var dictionary: [String: MLFeatureValue] = [:]
        dictionary.reserveCapacity(bundle.features.count)

        for featureName in bundle.features {
            guard let value = featurePool[featureName] else {
                throw CoreMLForecastServiceError.missingFeature(featureName, modelName: key.mlModelName)
            }
            dictionary[featureName] = MLFeatureValue(double: value)
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: dictionary)
        let output = try bundle.model.prediction(from: provider)
        return try extractPrediction(from: output, expectedName: key.target.outputFeatureName)
    }

    private func extractPrediction(
        from output: MLFeatureProvider,
        expectedName: String
    ) throws -> Double {
        if let value = output.featureValue(for: expectedName) {
            return value.doubleValue
        }

        let availableNames = Array(output.featureNames).sorted()
        if let firstNumeric = availableNames.compactMap({ output.featureValue(for: $0) }).first(where: { $0.type == .double || $0.type == .int64 }) {
            return firstNumeric.doubleValue
        }

        throw CoreMLForecastServiceError.invalidOutput(expected: expectedName, available: availableNames)
    }

    private static func loadModel(
        named name: String,
        configuration: MLModelConfiguration
    ) throws -> MLModel {
        if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            return try MLModel(contentsOf: compiledURL, configuration: configuration)
        }

        if let modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodel") {
            let compiledURL = try MLModel.compileModel(at: modelURL)
            return try MLModel(contentsOf: compiledURL, configuration: configuration)
        }

        throw CoreMLForecastServiceError.modelNotFound(name)
    }

    private static func loadFeatureOrder(for key: ModelKey) -> [String] {
        guard let url = Bundle.main.url(forResource: key.jsonManifestName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data),
              let features = findFeatureList(in: object),
              !features.isEmpty else {
            return key.fallbackFeatures
        }

        return features
    }

    /// Supports these JSON shapes:
    /// - { "features_ordered": [...] }
    /// - { "features": [...] }
    /// - { "models": { "short_temp": { "features_ordered": [...] } } }
    /// - ["spot_num", "hour", ...]
    private static func findFeatureList(in object: Any) -> [String]? {
        if let list = object as? [String] {
            return list
        }

        if let dictionary = object as? [String: Any] {
            for key in ["features_ordered", "feature_names", "features", "input_features"] {
                if let list = dictionary[key] as? [String] {
                    return list
                }
            }

            for value in dictionary.values {
                if let nested = findFeatureList(in: value) {
                    return nested
                }
            }
        }

        if let array = object as? [Any] {
            for value in array {
                if let nested = findFeatureList(in: value) {
                    return nested
                }
            }
        }

        return nil
    }
}
