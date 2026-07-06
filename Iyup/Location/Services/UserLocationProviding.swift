import CoreLocation

protocol UserLocationProviding: Sendable {
    func requestCurrentLocation() async throws -> CLLocationCoordinate2D
}
