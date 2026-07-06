import CoreLocation

struct NearbyPlace: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension NearbyPlace {
    static let tamanBenderaPusaka = NearbyPlace(
        id: "taman_bendera_pusaka",
        name: "Taman Bendera Pusaka",
        latitude: -6.1754,
        longitude: 106.8272
    )
}
