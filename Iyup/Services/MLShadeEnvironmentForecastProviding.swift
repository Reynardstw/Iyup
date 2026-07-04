import Foundation

/// Forecast provider used by MLShadeEnvironmentScoringEngine.
///
/// The deterministic shadow pipeline produces ShadowIntervalResult first.
/// This protocol adds environment prediction points on top of that timeline.
protocol MLShadeEnvironmentForecastProviding: Sendable {
    func forecast(
        for shadowResult: ShadowIntervalResult,
        referenceDate: Date,
        debugRunID: String
    ) async throws -> [MLShadeEnvironmentForecastPoint]
}

extension MLShadeEnvironmentForecastProviding {
    func forecast(
        for shadowResult: ShadowIntervalResult,
        referenceDate: Date
    ) async throws -> [MLShadeEnvironmentForecastPoint] {
        try await forecast(
            for: shadowResult,
            referenceDate: referenceDate,
            debugRunID: "NO-RUN-ID"
        )
    }
}
