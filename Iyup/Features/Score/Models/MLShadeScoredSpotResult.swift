import Foundation

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
    let meanPredictedOccupancy: Double
    let maxPredictedOccupancy: Double

    let environmentReasons: [String]

    var spot: ParkSpot { shadowResult.spot }

    var occupancyLabel: String {
        switch meanPredictedOccupancy {
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
