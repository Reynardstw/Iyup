import Foundation

struct PreviewWeatherService: WeatherProviding {
    private let snapshot: WeatherSnapshot

    init(
        snapshot: WeatherSnapshot = WeatherSnapshot(
            asOf: Date(),
            temperatureCelsius: 31.0,
            apparentTemperatureCelsius: 34.2,
            dewPointCelsius: 24.1,
            condition: "Berawan Sebagian",
            symbolName: "cloud.sun.fill",
            isDaylight: true,
            humidity: 0.68,
            cloudCover: 0.40,
            uvIndexValue: 8,
            uvIndexCategory: "Tinggi",
            pressureMillibars: 1009.4,
            pressureTrend: "Stabil",
            visibilityMeters: 14200,
            precipitationIntensityMmPerHour: 0.0,
            windSpeedKmh: 12.4,
            windGustKmh: 20.1,
            windDirectionDegrees: 135,
            windCompassDirection: "Tenggara"
        )
    ) {
        self.snapshot = snapshot
    }

    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        snapshot
    }

    func fetchHourlyForecast(
        latitude: Double,
        longitude: Double,
        startHour: Int,
        endHour: Int
    ) async throws -> [HourlyWeatherPoint] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        let today = Date()

        return stride(from: startHour, through: endHour, by: 1).compactMap { hour in
            guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) else {
                return nil
            }

            let peakFactor = max(0, sin(Double(hour - 6) / 12.0 * .pi))

            return HourlyWeatherPoint(
                date: date,
                hour: hour,
                temperatureCelsius: 26.0 + 8.0 * peakFactor,
                humidity: 0.75 - 0.20 * peakFactor,
                condition: peakFactor > 0.6 ? "Cerah" : "Berawan Sebagian",
                symbolName: peakFactor > 0.6 ? "sun.max.fill" : "cloud.sun.fill"
            )
        }
    }
}
