import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class LocationDistanceViewModel {
    let destination: NearbyPlace

    private(set) var userCoordinate: CLLocationCoordinate2D?
    private(set) var distanceMeters: Double?
    private(set) var isLoading = false
    var errorMessage: String?

    private let locationService: any UserLocationProviding

    init(locationService: any UserLocationProviding, destination: NearbyPlace) {
        self.locationService = locationService
        self.destination = destination
    }

    var distanceText: String? {
        guard let distanceMeters else { return nil }
        if distanceMeters < 1000 {
            return String(format: "%.0f m", distanceMeters)
        }
        return String(format: "%.2f km", distanceMeters / 1000)
    }

    func locate() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let coordinate = try await locationService.requestCurrentLocation()
            userCoordinate = coordinate
            distanceMeters = straightLineDistance(from: coordinate, to: destination.coordinate)
        } catch {
            userCoordinate = nil
            distanceMeters = nil
            errorMessage = error.localizedDescription
        }
    }

    private func straightLineDistance(
        from origin: CLLocationCoordinate2D,
        to target: CLLocationCoordinate2D
    ) -> Double {
        let originLocation = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
        return originLocation.distance(from: targetLocation)
    }
}
