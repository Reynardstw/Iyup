import Foundation

struct HourlyWeatherPoint: Equatable, Sendable {
    let date: Date
    let hour: Int
    let temperatureCelsius: Double
    let humidity: Double
    let condition: String
    let symbolName: String
}
