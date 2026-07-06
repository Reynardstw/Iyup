import Foundation

struct PreviewAnalyticsWeatherService: AnalyticsWeatherProviding {
    func fetchLastSevenNoonSnapshots(
        latitude: Double,
        longitude: Double,
        calendar: Calendar
    ) async throws -> [AnalyticsWeatherNoonSnapshot] {
        let todayNoon = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()

        return (0..<7).compactMap { index -> AnalyticsWeatherNoonSnapshot? in
            guard let date = calendar.date(byAdding: .day, value: index - 6, to: todayNoon) else {
                return nil
            }

            return AnalyticsWeatherNoonSnapshot(
                date: date,
                temperatureCelsius: 29.5 + Double(index % 3),
                humidityPercent: 62 + Double(index * 2),
                cloudCoverPercent: 35 + Double(index * 6),
                precipitationMillimeters: index == 4 ? 2.1 : Double(index % 2) * 0.5,
                windSpeedKmh: 8 + Double(index * 2),
                condition: index == 4 ? "Rain" : "Partly Cloudy"
            )
        }
    }
}
