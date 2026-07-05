import Foundation
import simd

struct ParkSpot: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let position: SIMD3<Float>
}
