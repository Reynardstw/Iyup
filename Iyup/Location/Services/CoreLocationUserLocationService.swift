import CoreLocation

final class CoreLocationUserLocationService: NSObject, UserLocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        let status = try await resolvedAuthorizationStatus()

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationDistanceError.authorizationDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            if locationContinuation != nil {
                locationContinuation?.resume(throwing: LocationDistanceError.requestReplaced)
                locationContinuation = nil
            }
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private func resolvedAuthorizationStatus() async throws -> CLAuthorizationStatus {
        let status = manager.authorizationStatus

        if status != .notDetermined {
            return status
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let authorizationContinuation else { return }

        let status = manager.authorizationStatus
        if status == .notDetermined { return }

        self.authorizationContinuation = nil
        authorizationContinuation.resume(returning: status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationContinuation?.resume(throwing: LocationDistanceError.locationUnavailable)
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: location.coordinate)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}
