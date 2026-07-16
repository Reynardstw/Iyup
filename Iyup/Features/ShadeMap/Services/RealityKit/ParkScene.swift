import Foundation
import RealityKit
import UIKit
import Combine

@MainActor
final class ParkScene {
    private let container = Entity()
    private let worldRoot = Entity()
    private let cameraAnchor = Entity()

    private let sunLight = DirectionalLight()
    private let fillLight = DirectionalLight()

    private var targetWorld: SIMD3<Float> = .zero

    private var glowingBalls: [ModelEntity] = []
    private var glowSubscription: Cancellable?
    private var glowStart = Date()
    private weak var realityScene: RealityKit.Scene?

    private var pinTemplate: Entity?

    private func loadPinTemplate() async {
        guard let url = Self.resourceURL(
            name: "map_pin_location_pin",
            extensionName: "usdz",
            subdirectories: [nil, "Resources/RealityKit"]
        ) else {
            print("pin usdz ga ketemu")
            return
        }
        do {
            pinTemplate = try await Entity(contentsOf: url)
        } catch {
            print("gagal load pin:", error.localizedDescription)
        }
    }

    private var cameraController: CameraController!

    private var spotLookup: [String: ShadeSpot] = [:]

    private let shadeService = ShadeSpotService()
    private var shadeMarkers: [Entity] = []

    func tilt(dy: Float) { cameraController.tilt(dy: dy) }

    func syncController(position: SIMD3<Float>, target: SIMD3<Float>) {
        cameraController.sync(position: position, target: target)
    }

    func prepareShadeSpotsIfNeeded() {
        guard shadeMarkers.isEmpty else { return }

        let spots = shadeService.spots()
        for spot in spots {
            let marker = makeMarker(spot: spot)
            marker.position = spot.position
            marker.position.y += -3.5
            marker.isEnabled = false
            worldRoot.addChild(marker)
            shadeMarkers.append(marker)
            spotLookup[marker.name] = spot
        }
        print("marker prepared:", shadeMarkers.count)
    }

    func showShadeSpots() {
        prepareShadeSpotsIfNeeded()
        shadeMarkers.forEach { $0.isEnabled = true }
    }

    private func makeMarker(spot: ShadeSpot) -> Entity {
        let wrapper = Entity()
        let markerName = "shade_\(spot.id)"
        wrapper.name = markerName

        let purple = UIColor(named: "AccentColor") ?? UIColor.systemPurple

        let stemMesh = MeshResource.generateCylinder(height: 1.2, radius: 0.08)
        var stemMat = PhysicallyBasedMaterial()
        stemMat.baseColor = .init(tint: purple)
        stemMat.roughness = 0.6
        let stem = ModelEntity(mesh: stemMesh, materials: [stemMat])
        stem.position.y = 0.6
        wrapper.addChild(stem)

        let ballMesh = MeshResource.generateSphere(radius: 0.35)
        var ballMat = PhysicallyBasedMaterial()
        ballMat.baseColor = .init(tint: purple)
        ballMat.roughness = 0.4
        ballMat.emissiveColor = .init(color: purple)
        ballMat.emissiveIntensity = 0
        let ball = ModelEntity(mesh: ballMesh, materials: [ballMat])
        ball.position.y = 1.4

        let shadowComponent = DynamicLightShadowComponent(castsShadow: false)

        stem.components.set(shadowComponent)
        ball.components.set(shadowComponent)

        ball.name = markerName
        wrapper.addChild(ball)

        wrapper.scale = [3, 3, 3]

        wrapper.position.y = -3.5

        let shape = ShapeResource.generateSphere(radius: 0.35 * 1.5)
        ball.components.set(CollisionComponent(shapes: [shape]))
        ball.components.set(InputTargetComponent())

        return wrapper
    }

    func spotForEntity(_ name: String) -> ShadeSpot? {
        spotLookup[name]
    }

    func worldPositionForEntity(_ name: String) -> SIMD3<Float>? {
        guard let marker = shadeMarkers.first(where: { $0.name == name }) else { return nil }
        return marker.position(relativeTo: nil)
    }

    func rotate(dx: Float) { cameraController.rotate(dx: dx) }
    func zoom(delta: Float) { cameraController.zoom(delta: delta) }
    func pan(dx: Float, dy: Float) { cameraController.pan(dx: dx, dy: dy) }
    func focusOn(_ p: SIMD3<Float>) { cameraController.focus(on: p) }
    func resetCamera() { cameraController.reset() }
    func focusPin(_ p: SIMD3<Float>) { cameraController.focusPin(on: p) }

    func startGlowLoop(scene: RealityKit.Scene) {
        realityScene = scene
        glowStart = Date()
        glowSubscription?.cancel()
        glowSubscription = scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
            guard let self else { return }
            let t = Date().timeIntervalSince(self.glowStart)

            let wave = (sin(t * 2 * .pi / 1.3) + 1) / 2
            let intensity = Float(0.2 + wave * 2.5)
            let scale = Float(1.0 + wave * 0.4)

            for ball in self.glowingBalls {
                if var mat = ball.model?.materials.first as? PhysicallyBasedMaterial {
                    mat.emissiveIntensity = intensity
                    ball.model?.materials[0] = mat
                }
                ball.scale = [scale, scale, scale]
            }
        }
    }

    func hideShadeSpots() {
        shadeMarkers.forEach { $0.isEnabled = false }
        glowingBalls.removeAll()
    }

    func pauseGlowLoop() {
        glowSubscription?.cancel()
        glowSubscription = nil
    }

    func resumeGlowLoop() {
        if let scene = realityScene {
            startGlowLoop(scene: scene)
        }
    }

    func updateGlow(safeSpotIDs: Set<String>) {
        glowingBalls.removeAll()

        for marker in shadeMarkers {
            guard let spot = spotLookup[marker.name],
                  let ball = marker.children.first(where: { $0.name == marker.name }) as? ModelEntity else {
                continue
            }

            if safeSpotIDs.contains(spot.spotID) {
                glowingBalls.append(ball)
            } else {
                if var mat = ball.model?.materials.first as? PhysicallyBasedMaterial {
                    mat.emissiveIntensity = 0
                    ball.model?.materials[0] = mat
                }
                ball.scale = [1, 1, 1]
            }
        }
    }

    private let sunPositionService = OfficialSunKitSunPositionService()
    private let sunVectorConverter = SunVectorConverter(
        zAxisDirection: .northNegative
    )
    private func setupCamera() {
        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 60
        cameraAnchor.addChild(cam)
        cameraAnchor.position = [3, 6, 3.5]
        cameraAnchor.look(at: [-0.5, -0.75, 0], from: cameraAnchor.position, relativeTo: nil)
        container.addChild(cameraAnchor)
        cameraController = CameraController(anchor: cameraAnchor)
    }

    func moveCamera(to position: SIMD3<Float>, target: SIMD3<Float>, duration: TimeInterval = 0.8) {
        let temp = Entity()
        temp.position = position
        temp.look(at: target, from: position, relativeTo: nil)
        cameraAnchor.move(to: temp.transform, relativeTo: nil, duration: duration)
    }

    private var didBuild = false

    private static var cachedPark: Entity?

    func build() async -> Entity {
        if didBuild { return container }
        didBuild = true
        container.addChild(worldRoot)

        setupSunLight()
        setupFillLight()
        setupCamera()

        guard let url = Self.resourceURL(
            name: "park",
            extensionName: "usdz",
            subdirectories: [nil, "Resources/RealityKit"]
        ) else {
            print("park.usdz tidak ditemukan di bundle")
            return container
        }

        do {
            let park: Entity
            if let cached = Self.cachedPark {
                park = cached.clone(recursive: true)
            } else {
                let loaded = try await Entity(contentsOf: url)
                Self.cachedPark = loaded
                park = loaded.clone(recursive: true)
            }
            worldRoot.addChild(park)
            normalizeParkScale(park)
            await loadPinTemplate()

        } catch {
            print("Gagal load park.usdz: \(error.localizedDescription)")
        }

        return container
    }

    func setSun(
        hour: Double,
        location: ParkLocation
    ) {
        let sun = sunPosition(
            hour: hour,
            location: location
        )

        let altitudeFactor = Float(
            max(0, min(1, sin(sun.altitudeDegrees * .pi / 180)))
        )

        guard sun.altitudeDegrees > 0 else {
            sunLight.light.intensity = 0
            fillLight.light.intensity = 30
            return
        }

        sunLight.light.intensity = 500 + 2300 * altitudeFactor

        let sunDirection = sunVectorConverter.directionVector(
            from: sun
        )

        sunLight.look(
            at: targetWorld,
            from: targetWorld + sunDirection,
            relativeTo: nil
        )

        fillLight.light.intensity = 30 + 120 * altitudeFactor
    }

    func sunPosition(
        hour: Double,
        location: ParkLocation
    ) -> SunPosition {
        let date = Self.jakartaDate(hour: hour)

        do {
            return try sunPositionService.position(
                at: date,
                location: location
            )
        } catch {
            print("Gagal menghitung posisi matahari: \(error.localizedDescription)")

            return SunPosition(
                altitudeDegrees: 0,
                azimuthDegrees: 0
            )
        }
    }

    private func setupSunLight() {
        sunLight.light.color = .white
        sunLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 8,
            depthBias: 1.0
        )

        container.addChild(sunLight)
    }

    private func setupFillLight() {
        fillLight.light.color = .white

        fillLight.look(
            at: [0, 0, 0],
            from: [-3, 6, -2],
            relativeTo: nil
        )

        container.addChild(fillLight)
    }

    private func normalizeParkScale(_ park: Entity) {
        let bounds = park.visualBounds(relativeTo: worldRoot)
        let center = bounds.center
        let extents = bounds.extents

        let longestSide = max(extents.x, extents.z)
        let scale = longestSide > 0 ? 6.0 / longestSide : 1.0

        worldRoot.scale = [scale, scale, scale]
        worldRoot.position = -center * scale
        targetWorld = .zero
    }

    private static func resourceURL(
        name: String,
        extensionName: String,
        subdirectories: [String?]
    ) -> URL? {
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: name,
                withExtension: extensionName,
                subdirectory: subdirectory
            ) {
                return url
            }
        }
        return nil
    }

    static func jakartaDate(hour: Double) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current

        let wholeHour = Int(hour)
        let minute = Int(round((hour - Double(wholeHour)) * 60))

        var components = DateComponents()
        components.timeZone = TimeZone(identifier: "Asia/Jakarta")
        components.year = 2026
        components.month = 3
        components.day = 7
        components.hour = wholeHour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components) ?? Date()
    }
}

extension Entity {
    func forEachDescendant(_ body: (Entity) -> Void) {
        body(self)
        for child in children {
            child.forEachDescendant(body)
        }
    }
}
