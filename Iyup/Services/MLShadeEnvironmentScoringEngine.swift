import Foundation

/// Combines deterministic shadow output with ML/environment forecasts.
///
/// Existing deterministic pipeline stays intact:
/// ShadeRecommendationEngine -> [ShadowIntervalResult]
/// This service only adds the final scoring layer on top.
struct MLShadeEnvironmentScoringEngine: Sendable {
    private let forecastService: any MLShadeEnvironmentForecastProviding
    private let scoringService: MLShadeScoringService

    init(
        forecastService: any MLShadeEnvironmentForecastProviding,
        scoringService: MLShadeScoringService = MLShadeScoringService()
    ) {
        self.forecastService = forecastService
        self.scoringService = scoringService
    }

    func score(
        shadowResults: [ShadowIntervalResult],
        referenceDate: Date = Date()
    ) async throws -> [MLShadeScoredSpotResult] {
        try await score(
            shadowResults: shadowResults,
            referenceDate: referenceDate,
            debugRunID: "SC-" + String(UUID().uuidString.prefix(8))
        )
    }

    func score(
        shadowResults: [ShadowIntervalResult],
        referenceDate: Date = Date(),
        debugRunID: String
    ) async throws -> [MLShadeScoredSpotResult] {
        print("🧮 [MLShade][\(debugRunID)] ScoringEngine.score() started")
        print("🧮 [MLShade][\(debugRunID)] Forecast service type: \(type(of: forecastService))")
        print("🧮 [MLShade][\(debugRunID)] Shadow results count: \(shadowResults.count)")

        var scoredResults: [MLShadeScoredSpotResult] = []

        for shadowResult in shadowResults {
            print("📍 [MLShade][\(debugRunID)] Scoring spot: \(shadowResult.spot.id) - \(shadowResult.spot.name)")
            print("📍 [MLShade][\(debugRunID)] Timeline count for \(shadowResult.spot.id): \(shadowResult.timeline.count)")

            let forecastPoints = try await forecastService.forecast(
                for: shadowResult,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            print("🌤️ [MLShade][\(debugRunID)] Forecast points for \(shadowResult.spot.id): \(forecastPoints.count)")

            guard !forecastPoints.isEmpty else {
                print("⚠️ [MLShade][\(debugRunID)] Skip \(shadowResult.spot.id) because forecastPoints is empty")
                continue
            }

            let scored = makeScoredResult(
                shadowResult: shadowResult,
                forecastPoints: forecastPoints
            )

            print("✅ [MLShade][\(debugRunID)] Scored \(shadowResult.spot.id): finalScore=\(scored.finalScore), meanTemp=\(scored.meanPredictedTemperature), meanLux=\(scored.meanPredictedLux), maxOcc=\(scored.maxPredictedOccupancy)")

            scoredResults.append(scored)
        }

        let sortedResults = scoredResults.sorted { lhs, rhs in
            if lhs.finalScore != rhs.finalScore {
                return lhs.finalScore > rhs.finalScore
            }

            if lhs.shadowResult.shadowForecastScore != rhs.shadowResult.shadowForecastScore {
                return lhs.shadowResult.shadowForecastScore > rhs.shadowResult.shadowForecastScore
            }

            return lhs.shadowResult.longestDirectSunStreakMinutes < rhs.shadowResult.longestDirectSunStreakMinutes
        }

        print("✅ [MLShade][\(debugRunID)] ScoringEngine.score() finished")
        print("🏆 [MLShade][\(debugRunID)] Sorted scored results count: \(sortedResults.count)")

        return sortedResults
    }

    private func makeScoredResult(
        shadowResult: ShadowIntervalResult,
        forecastPoints: [MLShadeEnvironmentForecastPoint]
    ) -> MLShadeScoredSpotResult {
        let count = Double(forecastPoints.count)
        let meanLux = forecastPoints.map(\.lux).reduce(0.0, +) / count
        let meanTemperature = forecastPoints.map(\.temperatureCelsius).reduce(0.0, +) / count

        // Conservative: crowd penalty follows the most crowded prediction in the interval.
        let maxOccupancy = forecastPoints.map(\.occupancy).max() ?? 0.0

        let stability = scoringService.shadeStability(timeline: shadowResult.timeline)
        let lightScore = scoringService.lightScore(lux: meanLux)
        let temperatureScore = scoringService.temperatureScore(celsius: meanTemperature)
        let occupancyPenalty = scoringService.occupancyPenalty(occupancy: maxOccupancy)

        let finalScore = scoringService.finalForecastScore(
            shadowForecastScore: shadowResult.shadowForecastScore,
            shadeStability: stability,
            expectedLightScore: lightScore,
            expectedTemperatureScore: temperatureScore,
            occupancyPenalty: occupancyPenalty
        )

        return MLShadeScoredSpotResult(
            shadowResult: shadowResult,
            finalScore: finalScore,
            shadeStability: stability,
            expectedLightScore: lightScore,
            expectedTemperatureScore: temperatureScore,
            occupancyPenalty: occupancyPenalty,
            meanPredictedLux: meanLux,
            meanPredictedTemperature: meanTemperature,
            maxPredictedOccupancy: maxOccupancy,
            environmentReasons: makeEnvironmentReasons(
                meanLux: meanLux,
                meanTemperature: meanTemperature,
                maxOccupancy: maxOccupancy
            )
        )
    }

    private func makeEnvironmentReasons(
        meanLux: Double,
        meanTemperature: Double,
        maxOccupancy: Double
    ) -> [String] {
        var reasons: [String] = []

        if meanLux > 3_000 {
            reasons.append("Prediksi cahaya cukup tinggi, rata-rata sekitar \(Int(meanLux.rounded())) lux.")
        }

        if meanTemperature > 31 {
            reasons.append(String(format: "Prediksi suhu cenderung panas, rata-rata %.1f°C.", meanTemperature))
        }

        if maxOccupancy > 0.60 {
            reasons.append("Prediksi occupancy mencapai \(Int((maxOccupancy * 100).rounded()))% pada interval ini.")
        }

        return reasons
    }
}
