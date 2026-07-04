import Foundation

/// One forecast point for one spot at one sampled time.
/// This only contains environment forecasts. Shadow remains deterministic
/// from ShadowIntervalCalculator and is not predicted by ML.
struct MLShadeEnvironmentForecastPoint: Equatable, Sendable {
    let sampleDate: Date
    let lux: Double
    let temperatureCelsius: Double

    /// 0.0 = empty, 1.0 = full.
    let occupancy: Double
}
