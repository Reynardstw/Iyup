import Foundation
import CoreLocation
import SunKit

/// Adapter resmi untuk package SunKit-Swift/SunKit.
///
/// SunKit hanya menghitung posisi matahari, yaitu altitude dan azimuth.
/// Logic bayangan tetap dihitung oleh ShadowIntervalCalculator melalui
/// SunVectorConverter + ShadowRaycastProviding.
struct OfficialSunKitSunPositionService: SunPositionProviding {
    func position(
        at date: Date,
        location: ParkLocation
    ) throws -> SunPosition {
        let coordinate = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )

        let timeZone = TimeZone(identifier: location.timeZoneIdentifier)
            ?? location.timeZone

        var sun = Sun(
            location: coordinate,
            timeZone: timeZone
        )

        sun.setDate(date)

        return SunPosition(
            altitudeDegrees: sun.altitude.degrees,
            azimuthDegrees: sun.azimuth.degrees
        )
    }
}
