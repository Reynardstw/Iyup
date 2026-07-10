import Foundation

struct MLShadeMockEnvironmentForecastService: MLShadeEnvironmentForecastProviding {
    func forecast(
        for shadowResult: ShadowIntervalResult,
        referenceDate: Date,
        debugRunID: String
    ) async throws -> [MLShadeEnvironmentForecastPoint] {

        guard !shadowResult.timeline.isEmpty else {
            throw MLShadeForecastError.emptyTimeline(shadowResult.spot.name)
        }

        return shadowResult.timeline.map { entry in
            let shaded = entry.isShaded
            let altitude = max(0.0, entry.sunPosition.altitudeDegrees)

            let lux = shaded ? 900.0 : min(70_000.0, 8_000.0 + altitude * 850.0)
            let temperature = shaded ? 30.0 : min(36.0, 30.0 + altitude / 25.0)
            let occupancy = shaded ? 0.45 : 0.25

            return MLShadeEnvironmentForecastPoint(
                sampleDate: entry.sampleDate,
                lux: lux,
                temperatureCelsius: temperature,
                occupancy: occupancy
            )
        }
    }
}
