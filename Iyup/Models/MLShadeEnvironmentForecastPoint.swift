import Foundation




struct MLShadeEnvironmentForecastPoint: Equatable, Sendable {
    let sampleDate: Date
    let lux: Double
    let temperatureCelsius: Double

    
    let occupancy: Double
}
