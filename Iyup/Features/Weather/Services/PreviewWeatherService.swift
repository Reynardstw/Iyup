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
}
