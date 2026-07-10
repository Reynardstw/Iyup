import Foundation
import Observation

@MainActor
@Observable
final class MLShadeRecommendationViewModel {
    var shadowResults: [ShadowIntervalResult] = []
    var scoredResults: [MLShadeScoredSpotResult] = []
    var errorMessage: String?
    var isCalculating = false

    var startDate: Date
    var endDate: Date
    var stepMinutes: Int

    private let recommendationEngine: ShadeRecommendationEngine
    private let scoringEngine: MLShadeEnvironmentScoringEngine
    private let location: ParkLocation
    private let spots: [ParkSpot]

    init(
        recommendationEngine: ShadeRecommendationEngine,
        scoringEngine: MLShadeEnvironmentScoringEngine,
        location: ParkLocation,
        spots: [ParkSpot],
        startDate: Date,
        endDate: Date,
        stepMinutes: Int = 15
    ) {
        self.recommendationEngine = recommendationEngine
        self.scoringEngine = scoringEngine
        self.location = location
        self.spots = spots
        self.startDate = startDate
        self.endDate = endDate
        self.stepMinutes = stepMinutes
    }

    func calculate() async {
        await calculate(debugRunID: "VM-" + String(UUID().uuidString.prefix(8)))
    }

    func calculate(debugRunID: String) async {

        isCalculating = true
        errorMessage = nil

        defer {
            isCalculating = false
        }

        do {
            let request = ShadowIntervalRequest(
                location: location,
                startDate: startDate,
                endDate: endDate,
                stepMinutes: stepMinutes,
                spots: spots
            )

            let deterministicResults = try recommendationEngine.recommend(request: request)

            shadowResults = deterministicResults

            scoredResults = try await scoringEngine.score(
                shadowResults: deterministicResults,
                referenceDate: startDate,
                debugRunID: debugRunID
            )
        } catch {
            shadowResults = []
            scoredResults = []
            errorMessage = error.localizedDescription
        }
    }
}
