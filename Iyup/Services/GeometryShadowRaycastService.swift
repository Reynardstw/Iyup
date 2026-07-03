import Foundation
import simd

struct ShadowOccluderSphere: Identifiable, Equatable, Sendable {
    let id: String
    let center: SIMD3<Float>
    let radius: Float
}

/// Geometry-only raycast service for validating the algorithm before connecting RealityKit.
/// Each occluder is represented as a sphere.
struct GeometryShadowRaycastService: ShadowRaycastProviding {
    let occluders: [ShadowOccluderSphere]

    func isPointShaded(
        point: SIMD3<Float>,
        sunDirection: SIMD3<Float>
    ) throws -> Bool {
        let normalizedDirection = simd_normalize(sunDirection)

        return occluders.contains { occluder in
            rayIntersectsSphere(
                origin: point,
                direction: normalizedDirection,
                sphereCenter: occluder.center,
                sphereRadius: occluder.radius
            )
        }
    }

    private func rayIntersectsSphere(
        origin: SIMD3<Float>,
        direction: SIMD3<Float>,
        sphereCenter: SIMD3<Float>,
        sphereRadius: Float
    ) -> Bool {
        let originToCenter = origin - sphereCenter

        let a = simd_dot(direction, direction)
        let b = 2.0 * simd_dot(originToCenter, direction)
        let c = simd_dot(originToCenter, originToCenter) - sphereRadius * sphereRadius

        let discriminant = b * b - 4.0 * a * c

        guard discriminant >= 0 else {
            return false
        }

        let sqrtDiscriminant = sqrt(discriminant)
        let t1 = (-b - sqrtDiscriminant) / (2.0 * a)
        let t2 = (-b + sqrtDiscriminant) / (2.0 * a)

        let minimumHitDistance: Float = 0.05

        return t1 > minimumHitDistance || t2 > minimumHitDistance
    }
}
