import Foundation

struct ShadowIntervalResult: Identifiable, Equatable, Sendable {
    let id = UUID()

    let spot: ParkSpot
    let timeline: [ShadowTimelineEntry]

    let shadowForecastScore: Double
    let shadeDurationMinutes: Double
    let sunExposureMinutes: Double
    let longestDirectSunStreakMinutes: Double
    let firstSunExposureTime: Date?
    let safetyStatus: ShadowSafetyStatus
    let reason: String
}
