import WeatherKit
import CoreLocation

struct WeatherKitWeatherService: WeatherProviding {
    private let service = WeatherService.shared

    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather

        return WeatherSnapshot(
            asOf: current.date,
            temperatureCelsius: current.temperature.converted(to: .celsius).value,
            apparentTemperatureCelsius: current.apparentTemperature.converted(to: .celsius).value,
            dewPointCelsius: current.dewPoint.converted(to: .celsius).value,
            condition: current.condition.description,
            symbolName: current.symbolName,
            isDaylight: current.isDaylight,
            humidity: current.humidity,
            cloudCover: current.cloudCover,
            uvIndexValue: current.uvIndex.value,
            uvIndexCategory: current.uvIndex.category.description,
            pressureMillibars: current.pressure.converted(to: .millibars).value,
            pressureTrend: current.pressureTrend.description,
            visibilityMeters: current.visibility.converted(to: .meters).value,
            precipitationIntensityMmPerHour: current.precipitationIntensity.value,
            windSpeedKmh: current.wind.speed.converted(to: .kilometersPerHour).value,
            windGustKmh: current.wind.gust?.converted(to: .kilometersPerHour).value,
            windDirectionDegrees: current.wind.direction.converted(to: .degrees).value,
            windCompassDirection: current.wind.compassDirection.description
        )
    }
}
