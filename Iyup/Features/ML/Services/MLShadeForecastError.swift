import Foundation

enum MLShadeForecastError: LocalizedError {
    case manifestNotFound
    case modelUnavailable(String)
    case missingFeature(String, model: String)
    case invalidOutput(String, model: String, available: [String])
    case spotMappingNotFound(String)
    case emptyTimeline(String)

    var errorDescription: String? {
        switch self {
        case .manifestNotFound:
            return "Manifest fitur XGBoost tidak ditemukan di bundle. Pastikan model_features_*_xgb.json masuk Copy Bundle Resources."
        case .modelUnavailable(let name):
            return "Model Core ML '\(name)' belum tersedia di bundle. Pastikan .mlmodel masuk Target Membership / Copy Bundle Resources."
        case .missingFeature(let feature, let model):
            return "Fitur '\(feature)' tidak tersedia untuk model '\(model)'. Periksa feature builder/sensor provider."
        case .invalidOutput(let expected, let model, let available):
            return "Output '\(expected)' tidak ditemukan pada model '\(model)'. Output tersedia: \(available.joined(separator: ", "))."
        case .spotMappingNotFound(let spotID):
            return "Spot '\(spotID)' tidak ada pada spot_mapping XGBoost. Samakan ID spot app dengan mapping training."
        case .emptyTimeline(let spotName):
            return "Timeline shadow untuk \(spotName) kosong, forecast tidak bisa dihitung."
        }
    }
}
