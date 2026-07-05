import Foundation

struct SunPosition: Equatable, Sendable {
    
    
    let altitudeDegrees: Double

    
    
    let azimuthDegrees: Double

    var isAboveHorizon: Bool {
        altitudeDegrees > 0
    }
}
