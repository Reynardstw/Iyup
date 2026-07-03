import Foundation
import simd

protocol ShadowRaycastProviding {
    /// Returns true when the line from `point` toward the sun is blocked by an occluder.
    func isPointShaded(
        point: SIMD3<Float>,
        sunDirection: SIMD3<Float>
    ) throws -> Bool
}
