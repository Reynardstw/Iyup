import CoreLocation
import Foundation
import WeatherKit

struct WeatherKitAnalyticsWeatherService: AnalyticsWeatherProviding {
    private let service = WeatherService.shared

    func fetchLastSevenNoonSnapshots(
        latitude: Double,
        longitude: Double,
        calendar: Calendar
    ) async throws -> [AnalyticsWeatherNoonSnapshot] {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let noonDates = makeLastSevenNoonDates(calendar: calendar)

        guard let startDate = noonDates.first,
              let lastDate = noonDates.last,
              let endDate = calendar.date(byAdding: .hour, value: 1, to: lastDate) else {
            return []
        }

        let forecast = try await service.weather(
            for: location,
            including: .hourly(startDate: startDate, endDate: endDate)
        )

        let hourlyWeather = Array(forecast)

        return noonDates.compactMap { targetDate -> AnalyticsWeatherNoonSnapshot? in
            guard let closest = closestHour(
                to: targetDate,
                in: hourlyWeather,
                calendar: calendar
            ) else {
                return nil
            }

            return AnalyticsWeatherNoonSnapshot(
                date: targetDate,
                temperatureCelsius: closest.temperature.converted(to: .celsius).value,
                humidityPercent: closest.humidity * 100,
                cloudCoverPercent: closest.cloudCover * 100,
                precipitationMillimeters: closest.precipitationAmount.converted(to: .millimeters).value,
                windSpeedKmh: closest.wind.speed.converted(to: .kilometersPerHour).value,
                condition: closest.condition.description
            )
        }
    }

    private func makeLastSevenNoonDates(calendar: Calendar) -> [Date] {
        let now = Date()
        let todayNoon = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: now
        ) ?? now

        return (0..<7)
            .compactMap { offset in
                calendar.date(byAdding: .day, value: -offset, to: todayNoon)
            }
            .reversed()
    }

    private func closestHour(
        to targetDate: Date,
        in hourlyWeather: [HourWeather],
        calendar: Calendar
    ) -> HourWeather? {
        hourlyWeather
            .filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
            .min { left, right in
                abs(left.date.timeIntervalSince(targetDate)) < abs(right.date.timeIntervalSince(targetDate))
            }
    }
}
