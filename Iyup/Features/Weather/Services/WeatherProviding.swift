import Foundation

protocol WeatherProviding: Sendable {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot

    func fetchHourlyForecast(
        latitude: Double,
        longitude: Double,
        startHour: Int,
        endHour: Int
    ) async throws -> [HourlyWeatherPoint]
}
