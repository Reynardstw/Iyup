import Foundation
import RealityKit
import UIKit

@MainActor
final class ParkScene {
    private let container = Entity()
    private let worldRoot = Entity()
    private let cameraAnchor = Entity()

    private let sunLight = DirectionalLight()
    private let fillLight = DirectionalLight()

    private var targetWorld: SIMD3<Float> = .zero
    
    // ---------------------
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

    func showShadeSpots(forHour hour: Int) {
        // hapus lama
        shadeMarkers.forEach { $0.removeFromParent() }
        shadeMarkers.removeAll()

        let spots = shadeService.spots(forHour: hour)
        for spot in spots {
            let marker = makeMarker(spot: spot)
            marker.position = spot.position
            worldRoot.addChild(marker)
            shadeMarkers.append(marker)
            spotLookup[marker.name] = spot
        }
        print("marker dibuat:", shadeMarkers.count)
    }

    private func makeMarker(spot: ShadeSpot) -> Entity {
        let wrapper = Entity()

        if let template = pinTemplate {
            let pin = template.clone(recursive: true)
            pin.scale = [0.075, 0.075, 0.075]
            pin.position.y = -3

            pin.forEachDescendant { entity in
                guard var model = entity.components[ModelComponent.self] else { return }
                model.materials = model.materials.map { mat -> RealityKit.Material in
                    if let pbr = mat as? PhysicallyBasedMaterial {
                        return UnlitMaterial(color: pbr.baseColor.tint)
                    }
                    if let simple = mat as? SimpleMaterial {
                        return UnlitMaterial(color: simple.color.tint)
                    }
                    return mat
                }
                entity.components.set(model)
            }

            wrapper.addChild(pin)
        }

        let shape = ShapeResource.generateSphere(radius: 0.6)
        wrapper.components.set(CollisionComponent(shapes: [shape]))
        wrapper.components.set(InputTargetComponent())
        wrapper.name = "shade_\(spot.id)"
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
    
    func hideShadeSpots() {
        shadeMarkers.forEach { $0.removeFromParent() }
        shadeMarkers.removeAll()
    }
    
//    func resetCamera() {
//        cameraController.azimuth = 0
//        cameraController.elevation = 0.9
//        cameraController.distance = 5.5
//        cameraController.center = [0, 0, 0]
//        cameraController.update()
//    }
    
    // ----------------

    private let sunPositionService = OfficialSunKitSunPositionService()
    private let sunVectorConverter = SunVectorConverter(
        zAxisDirection: .northNegative
    )
    private func setupCamera() {
        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 60
        cameraAnchor.addChild(cam)
        cameraAnchor.position = [3,6, 3.5]
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
            print("checkpoint_final_4.usda tidak ditemukan di bundle")
            return container
        }

        do {
            let park = try await Entity(contentsOf: url)
            worldRoot.addChild(park)
            normalizeParkScale(park)
            await loadPinTemplate()   // ← taruh di sini

            let b = park.visualBounds(relativeTo: worldRoot)
            print("center:", b.center)
            print("extents:", b.extents)
            print("min:", b.min)
            print("max:", b.max)
            
        } catch {
            print("Gagal load checkpoint_final_4.usda: \(error.localizedDescription)")
        }
        

        
        return container
    }
    func setSun(
        hour: Int,
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
        hour: Int,
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

    static func jakartaDate(hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current

        var components = DateComponents()
        components.timeZone = TimeZone(identifier: "Asia/Jakarta")
        components.year = 2026
        components.month = 3
        components.day = 7
        components.hour = hour
        components.minute = 0
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
