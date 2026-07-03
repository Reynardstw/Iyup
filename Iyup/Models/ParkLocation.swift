import Foundation

struct ParkLocation: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}
