import Foundation
import RealityKit
import UIKit

@MainActor
final class ParkScene {
    private let container = Entity()
    private let worldRoot = Entity()

    private let sunLight = DirectionalLight()
    private let fillLight = DirectionalLight()

    private var targetWorld: SIMD3<Float> = .zero

    private let sunPositionService = OfficialSunKitSunPositionService()
    private let sunVectorConverter = SunVectorConverter(
        zAxisDirection: .northNegative
    )

    func build() async -> Entity {
        container.addChild(worldRoot)

        setupSunLight()
        setupFillLight()

        guard let url = Self.resourceURL(
            name: "checkpoint_final_4",
            extensionName: "usda",
            subdirectories: [nil, "Resources/Reality"]
        ) else {
            print("checkpoint_final_4.usda tidak ditemukan di bundle")
            return container
        }

        do {
            let park = try await Entity(contentsOf: url)
            worldRoot.addChild(park)
            normalizeParkScale(park)
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
        sunLight.light.color = .init(white: 1.0, alpha: 1.0)
        sunLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 8,
            depthBias: 1.0
        )

        container.addChild(sunLight)
    }

    private func setupFillLight() {
        fillLight.light.color = .init(white: 1.0, alpha: 1.0)
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
