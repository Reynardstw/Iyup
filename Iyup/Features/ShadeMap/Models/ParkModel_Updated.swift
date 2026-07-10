import Foundation

struct ParkModel: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var distanceInfo: String
    var isMapped: Bool // true: map 3D aktif, false: map dummy terkunci
}

/// Dipakai oleh ParkScene.setSun(...) dan ShadeMapViewModel. Nama ini disamakan
/// dengan pemakaian di file ShadeMapViewModel agar tidak error "Cannot find ParkLocation".
struct ParkShadeLocation {
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
}
