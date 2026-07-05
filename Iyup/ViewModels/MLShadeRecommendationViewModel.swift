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
        print("🧭 [MLShade][\(debugRunID)] ViewModel.calculate() started")
        print("🧭 [MLShade][\(debugRunID)] Location: lat=\(location.latitude), lon=\(location.longitude), tz=\(location.timeZoneIdentifier)")
        print("🧭 [MLShade][\(debugRunID)] Spots count: \(spots.count)")
        print("🧭 [MLShade][\(debugRunID)] Start: \(startDate)")
        print("🧭 [MLShade][\(debugRunID)] End: \(endDate)")
        print("🧭 [MLShade][\(debugRunID)] Step minutes: \(stepMinutes)")

        isCalculating = true
        errorMessage = nil

        defer {
            isCalculating = false
            print("🧭 [MLShade][\(debugRunID)] ViewModel.calculate() ended")
        }

        do {
            let request = ShadowIntervalRequest(
                location: location,
                startDate: startDate,
                endDate: endDate,
                stepMinutes: stepMinutes,
                spots: spots
            )

            print("🌳 [MLShade][\(debugRunID)] Calling deterministic shadow recommendation engine")
            let deterministicResults = try recommendationEngine.recommend(request: request)
            print("✅ [MLShade][\(debugRunID)] Shadow engine finished. Result count: \(deterministicResults.count)")

            for result in deterministicResults {
                print("🌳 [MLShade][\(debugRunID)] Shadow result: spot=\(result.spot.id), timeline=\(result.timeline.count), shadowScore=\(result.shadowForecastScore)")
            }

            shadowResults = deterministicResults

            print("🧮 [MLShade][\(debugRunID)] Calling ML scoring engine")
            scoredResults = try await scoringEngine.score(
                shadowResults: deterministicResults,
                referenceDate: Date(),
                debugRunID: debugRunID
            )

            print("✅ [MLShade][\(debugRunID)] ML scoring finished. Scored count: \(scoredResults.count)")
            for (index, result) in scoredResults.enumerated() {
                print("🏆 [MLShade][\(debugRunID)] Rank \(index + 1): spot=\(result.spot.id), name=\(result.spot.name), finalScore=\(result.finalScore), temp=\(result.meanPredictedTemperature), lux=\(result.meanPredictedLux), occ=\(result.maxPredictedOccupancy)")
            }
        } catch {
            print("❌ [MLShade][\(debugRunID)] ViewModel.calculate() failed: \(error)")

            shadowResults = []
            scoredResults = []
            errorMessage = error.localizedDescription
        }
    }
}
