import Foundation

struct AnalyticsWeatherNoonSnapshot: Identifiable, Equatable, Sendable {
    let id = UUID()
    let date: Date
    let temperatureCelsius: Double
    let humidityPercent: Double
    let cloudCoverPercent: Double
    let precipitationMillimeters: Double
    let windSpeedKmh: Double
    let condition: String
}
