import Foundation

struct SunPosition: Equatable, Sendable {
    /// Degrees from the horizon.
    /// 0 = horizon, 90 = directly overhead.
    let altitudeDegrees: Double

    /// Degrees from true north, clockwise.
    /// 0 = North, 90 = East, 180 = South, 270 = West.
    let azimuthDegrees: Double

    var isAboveHorizon: Bool {
        altitudeDegrees > 0
    }
}
