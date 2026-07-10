import Foundation
import RealityKit

struct ShadeSpot: Identifiable {
    let id = UUID()
    let position: SIMD3<Float>
    let hour: Int
    let level: ShadeLevel
    let spotID: String
}

enum ShadeLevel {
    case low, medium, high
}
