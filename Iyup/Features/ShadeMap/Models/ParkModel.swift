import Foundation

struct ParkModel: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var distanceInfo: String
    var isMapped: Bool
}

struct ParkShadeLocation {
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
}
