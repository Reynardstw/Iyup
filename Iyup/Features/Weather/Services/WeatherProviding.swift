protocol WeatherProviding: Sendable {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherSnapshot
}
