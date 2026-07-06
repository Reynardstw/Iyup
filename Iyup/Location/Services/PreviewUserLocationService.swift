import CoreLocation

final class PreviewUserLocationService: UserLocationProviding, @unchecked Sendable {
    private let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: -6.1900, longitude: 106.8200)) {
        self.coordinate = coordinate
    }

    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        coordinate
    }
}
