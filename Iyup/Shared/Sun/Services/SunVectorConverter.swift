import Foundation
import simd

enum SceneZAxisDirection: Sendable {
    case northPositive
    case northNegative
}

struct SunVectorConverter {
    let zAxisDirection: SceneZAxisDirection

    init(zAxisDirection: SceneZAxisDirection = .northPositive) {
        self.zAxisDirection = zAxisDirection
    }

    func directionVector(from sunPosition: SunPosition) -> SIMD3<Float> {
        let altitude = degreesToRadians(sunPosition.altitudeDegrees)
        let azimuth = degreesToRadians(sunPosition.azimuthDegrees)

        let horizontalLength = cos(altitude)

        let east = horizontalLength * sin(azimuth)
        let up = sin(altitude)
        let north = horizontalLength * cos(azimuth)

        let sceneNorth: Double = {
            switch zAxisDirection {
            case .northPositive:
                return north
            case .northNegative:
                return -north
            }
        }()

        let vector = SIMD3<Float>(
            Float(east),
            Float(up),
            Float(sceneNorth)
        )

        return simd_normalize(vector)
    }

    private func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180.0
    }
}
