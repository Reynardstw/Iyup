import RealityKit
import Foundation

@MainActor
final class CameraController {
    private let anchor: Entity

    var azimuth: Float = 0
    var elevation: Float = 0.9
    var distance: Float = 5.5
    var center: SIMD3<Float> = [0, 0, 0]

    let minDistance: Float = 2.5
    let maxDistance: Float = 8.75
    let minElevation: Float = 0.35
    let maxElevation: Float = 1.5

    let panBoundsX: ClosedRange<Float> = -1.1...1.1
    let panBoundsZ: ClosedRange<Float> = -3...3

    init(anchor: Entity) {
        self.anchor = anchor
    }

    func rotate(dx: Float) {
        azimuth += dx * 0.002
        update()
    }

    func zoom(delta: Float) {
        distance = clampF(distance - delta, minDistance, maxDistance)
        update()
    }

    func pan(dx: Float, dy: Float) {
        let s: Float = 0.004
        let forwardX = sin(azimuth)
        let forwardZ = cos(azimuth)
        let rightX = cos(azimuth)
        let rightZ = -sin(azimuth)

        center.x -= (rightX * dx + forwardX * dy) * s
        center.z -= (rightZ * dx + forwardZ * dy) * s
        center.x = clampF(center.x, panBoundsX.lowerBound, panBoundsX.upperBound)
        center.z = clampF(center.z, panBoundsZ.lowerBound, panBoundsZ.upperBound)
        update()
    }

    func focus(on point: SIMD3<Float>) {
        center = point
        center.x = clampF(center.x, panBoundsX.lowerBound, panBoundsX.upperBound)
        center.z = clampF(center.z, panBoundsZ.lowerBound, panBoundsZ.upperBound)
        let pos = anchor.position(relativeTo: nil)
        let diff = pos - center
        let curDist = length(diff)
        distance = clampF(curDist * 0.6, minDistance, maxDistance)
        elevation = clampF(asin(diff.y / curDist), minElevation, maxElevation)
        azimuth = atan2(diff.x, diff.z)
        update(animated: true)
    }

    func focusPin(on point: SIMD3<Float>) {
        center = point
        center.x = clampF(center.x, panBoundsX.lowerBound, panBoundsX.upperBound)
        center.z = clampF(center.z, panBoundsZ.lowerBound, panBoundsZ.upperBound)

        let pos = anchor.position(relativeTo: nil)
        let diff = pos - center
        azimuth = atan2(diff.x, diff.z)
        elevation = 0.6
        distance = 3.5
        update(animated: true)
    }

    func reset() {
        center = [0, -1.5, 0]
        distance = 8.75
        elevation = 1.32
        azimuth = 0.245
        update()
    }

    func update(animated: Bool = false) {
        let x = center.x + distance * cos(elevation) * sin(azimuth)
        let y = center.y + distance * sin(elevation)
        let z = center.z + distance * cos(elevation) * cos(azimuth)
        let pos = SIMD3<Float>(x, y, z)

        if animated {
            let temp = Entity()
            temp.position = pos
            temp.look(at: center, from: pos, relativeTo: nil)
            anchor.move(to: temp.transform, relativeTo: nil, duration: 0.5)
        } else {
            anchor.position = pos
            anchor.look(at: center, from: pos, relativeTo: nil)
        }
    }

    private func clampF(_ v: Float, _ lo: Float, _ hi: Float) -> Float {
        max(lo, min(hi, v))
    }

    func tilt(dy: Float) {
        elevation = clampF(elevation + dy * 0.002, minElevation, maxElevation)
        update()
    }

    func sync(position: SIMD3<Float>, target: SIMD3<Float>) {
        center = target
        let diff = position - target
        distance = length(diff)
        elevation = asin(diff.y / distance)
        azimuth = atan2(diff.x, diff.z)
    }
}
