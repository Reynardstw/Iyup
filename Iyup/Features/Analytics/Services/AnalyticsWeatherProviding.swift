import Foundation

protocol AnalyticsWeatherProviding: Sendable {
    func fetchLastSevenNoonSnapshots(
        latitude: Double,
        longitude: Double,
        calendar: Calendar
    ) async throws -> [AnalyticsWeatherNoonSnapshot]
}
