import Foundation

/// Final recommendation result after deterministic shadow result is combined
/// with environment forecast output and rule-based scoring.
///
/// This wraps ShadowIntervalResult. It does not replace the existing shadow-only result.
struct MLShadeScoredSpotResult: Identifiable, Equatable, Sendable {
    let id = UUID()

    let shadowResult: ShadowIntervalResult
    let finalScore: Double

    let shadeStability: Double
    let expectedLightScore: Double
    let expectedTemperatureScore: Double
    let occupancyPenalty: Double

    let meanPredictedLux: Double
    let meanPredictedTemperature: Double
    let maxPredictedOccupancy: Double

    let environmentReasons: [String]

    var spot: ParkSpot { shadowResult.spot }

    var occupancyLabel: String {
        switch maxPredictedOccupancy {
        case ..<0.31:
            return "Sepi"
        case ..<0.61:
            return "Sedang"
        case ..<0.86:
            return "Ramai"
        default:
            return "Penuh"
        }
    }
}
