import Foundation

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
