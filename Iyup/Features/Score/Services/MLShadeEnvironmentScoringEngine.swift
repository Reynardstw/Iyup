import Foundation



// Set true hanya saat butuh debug ML. Default off: hilangkan banjir log per recalc.
private let mlShadeVerboseLogging = false
@inline(__always) private func mlLog(_ message: @autoclosure () -> String) {
    if mlShadeVerboseLogging { Swift.print(message()) }
}

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
        mlLog("🧮 [MLShade][\(debugRunID)] ScoringEngine.score() started")
        mlLog("🧮 [MLShade][\(debugRunID)] Forecast service type: \(type(of: forecastService))")
        mlLog("🧮 [MLShade][\(debugRunID)] Shadow results count: \(shadowResults.count)")

        var scoredResults: [MLShadeScoredSpotResult] = []

        for shadowResult in shadowResults {
            mlLog("📍 [MLShade][\(debugRunID)] Scoring spot: \(shadowResult.spot.id) - \(shadowResult.spot.name)")
            mlLog("📍 [MLShade][\(debugRunID)] Timeline count for \(shadowResult.spot.id): \(shadowResult.timeline.count)")

            let forecastPoints = try await forecastService.forecast(
                for: shadowResult,
                referenceDate: referenceDate,
                debugRunID: debugRunID
            )

            mlLog("🌤️ [MLShade][\(debugRunID)] Forecast points for \(shadowResult.spot.id): \(forecastPoints.count)")

            guard !forecastPoints.isEmpty else {
                mlLog("⚠️ [MLShade][\(debugRunID)] Skip \(shadowResult.spot.id) because forecastPoints is empty")
                continue
            }

            let scored = makeScoredResult(
                shadowResult: shadowResult,
                forecastPoints: forecastPoints
            )

            mlLog("✅ [MLShade][\(debugRunID)] Scored \(shadowResult.spot.id): finalScore=\(scored.finalScore), meanTemp=\(scored.meanPredictedTemperature), meanLux=\(scored.meanPredictedLux), meanOcc=\(scored.meanPredictedOccupancy), maxOcc=\(scored.maxPredictedOccupancy)")

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

        mlLog("✅ [MLShade][\(debugRunID)] ScoringEngine.score() finished")
        mlLog("🏆 [MLShade][\(debugRunID)] Sorted scored results count: \(sortedResults.count)")

        return sortedResults
    }

    private func makeScoredResult(
        shadowResult: ShadowIntervalResult,
        forecastPoints: [MLShadeEnvironmentForecastPoint]
    ) -> MLShadeScoredSpotResult {
        let count = Double(forecastPoints.count)
        let meanLux = forecastPoints.map(\.lux).reduce(0.0, +) / count
        let meanTemperature = forecastPoints.map(\.temperatureCelsius).reduce(0.0, +) / count
        let meanOccupancy = forecastPoints.map(\.occupancy).reduce(0.0, +) / count
        let maxOccupancy = forecastPoints.map(\.occupancy).max() ?? 0.0

        let stability = scoringService.shadeStability(timeline: shadowResult.timeline)
        let lightScore = scoringService.lightScore(lux: meanLux)
        let temperatureScore = scoringService.temperatureScore(celsius: meanTemperature)
        let occupancyPenalty = scoringService.occupancyPenalty(occupancy: meanOccupancy)

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
            meanPredictedOccupancy: meanOccupancy,
            maxPredictedOccupancy: maxOccupancy,
            environmentReasons: makeEnvironmentReasons(
                meanLux: meanLux,
                meanTemperature: meanTemperature,
                meanOccupancy: meanOccupancy,
                maxOccupancy: maxOccupancy
            )
        )
    }

    private func makeEnvironmentReasons(
        meanLux: Double,
        meanTemperature: Double,
        meanOccupancy: Double,
        maxOccupancy: Double
    ) -> [String] {
        var reasons: [String] = []

        if meanLux > 3_000 {
            reasons.append("Prediksi cahaya cukup tinggi, rata-rata sekitar \(Int(meanLux.rounded())) lux.")
        }

        if meanTemperature > 31 {
            reasons.append(String(format: "Prediksi suhu cenderung panas, rata-rata %.1f°C.", meanTemperature))
        }

        if meanOccupancy > 0.60 {
            reasons.append("Prediksi occupancy rata-rata sekitar \(Int((meanOccupancy * 100).rounded()))% pada interval ini.")
        } else if maxOccupancy > 0.85 {
            reasons.append("Ada satu interval yang diprediksi ramai, puncaknya sekitar \(Int((maxOccupancy * 100).rounded()))%.")
        }

        return reasons
    }
}
