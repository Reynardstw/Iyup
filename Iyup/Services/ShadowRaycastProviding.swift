import Foundation
import simd

protocol ShadowRaycastProviding {
    
    func isPointShaded(
        point: SIMD3<Float>,
        sunDirection: SIMD3<Float>
    ) throws -> Bool
}
