import Foundation

protocol SunPositionProviding {
    func position(
        at date: Date,
        location: ParkLocation
    ) throws -> SunPosition
}
