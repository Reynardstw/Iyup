import Foundation
import CoreLocation
import SunKit


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
