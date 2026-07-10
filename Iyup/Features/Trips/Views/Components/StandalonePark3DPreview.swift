import SwiftUI
import RealityKit

struct StandalonePark3DPreview: View {
    let location: ParkLocation
    let hour: Double
    let highlightedSpotIDs: Set<String>

    @State private var scene = ParkScene()

    private let planTripCameraPosition = SIMD3<Float>(-1.45, 1.55, 0.45)
    private let planTripCameraTarget = SIMD3<Float>(0, -1.2, 0)
    private let standaloneDistanceMultiplier: Float = 1

    var body: some View {
        RealityView { content in
            let root = await scene.build()
            content.add(root)
            scene.setSun(hour: hour, location: location)
            scene.showShadeSpots()
            scene.updateGlow(safeSpotIDs: highlightedSpotIDs)

            if let realScene = root.scene {
                scene.startGlowLoop(scene: realScene)
            }

            applyPlanTripCamera(duration: 0)
        } update: { _ in
            scene.setSun(hour: hour, location: location)
            scene.showShadeSpots()
            scene.updateGlow(safeSpotIDs: highlightedSpotIDs)
            applyPlanTripCamera(duration: 0)
        }
        .allowsHitTesting(false)
        .background(Color.clear)
        .onDisappear {
            scene.pauseGlowLoop()
            scene.hideShadeSpots()
        }
    }

    private func applyPlanTripCamera(duration: TimeInterval) {
        scene.moveCamera(
            to: standaloneCameraPosition,
            target: planTripCameraTarget,
            duration: duration
        )
    }

    private var standaloneCameraPosition: SIMD3<Float> {
        planTripCameraTarget + (planTripCameraPosition - planTripCameraTarget) * standaloneDistanceMultiplier
    }
}
