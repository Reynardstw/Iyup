import Foundation

struct WeatherSnapshot: Equatable, Sendable {
    let asOf: Date

    let temperatureCelsius: Double
    let apparentTemperatureCelsius: Double
    let dewPointCelsius: Double

    let condition: String
    let symbolName: String
    let isDaylight: Bool

    let humidity: Double
    let cloudCover: Double
    let uvIndexValue: Int
    let uvIndexCategory: String

    let pressureMillibars: Double
    let pressureTrend: String

    let visibilityMeters: Double
    let precipitationIntensityMmPerHour: Double

    let windSpeedKmh: Double
    let windGustKmh: Double?
    let windDirectionDegrees: Double
    let windCompassDirection: String
}
