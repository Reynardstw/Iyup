import SwiftUI
import RealityKit

struct ShadeMapView: View {
    @State private var hour: Double = 10
    @State private var scene = ParkScene()

    private let parkLocation = ParkLocation(
        latitude: -6.245542,
        longitude: 106.794547,
        timeZoneIdentifier: "Asia/Jakarta"
    )

    var body: some View {
        ZStack(alignment: .topLeading) {
            skyGradient.ignoresSafeArea()

            RealityView { content in
                let root = await scene.build()
                content.add(root)

                scene.setSun(
                    hour: Int(hour.rounded()),
                    location: parkLocation
                )
            } update: { _ in
                scene.setSun(
                    hour: Int(hour.rounded()),
                    location: parkLocation
                )
            }
            .realityViewCameraControls(.orbit)
            .ignoresSafeArea()

            controls
        }
    }

    private var sun: SunPosition {
        scene.sunPosition(
            hour: Int(hour.rounded()),
            location: parkLocation
        )
    }

    private var dayFactor: Double {
        max(0, min(1, sin(sun.altitudeDegrees * .pi / 180)))
    }

    private var skyGradient: LinearGradient {
        let factor = dayFactor

        let topColor = Color(
            red: 0.05 + 0.35 * factor,
            green: 0.07 + 0.45 * factor,
            blue: 0.12 + 0.55 * factor
        )

        let bottomColor = Color(
            red: 0.03 + 0.20 * factor,
            green: 0.04 + 0.28 * factor,
            blue: 0.08 + 0.38 * factor
        )

        return LinearGradient(
            colors: [topColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Taman Bendera Pusaka 3D")
                .font(.headline)

            Text("Tanggal demo: 7 Mar 2026")
                .font(.caption2)
                .opacity(0.85)

            Text(
                String(
                    format: "Jam %02d:00 | Alt %.1f° | Az %.1f°",
                    Int(hour.rounded()),
                    sun.altitudeDegrees,
                    sun.azimuthDegrees
                )
            )
            .font(.caption)

            HStack {
                Text("06")
                    .font(.caption)

                Slider(value: $hour, in: 6...18, step: 1)

                Text("18")
                    .font(.caption)
            }

            Text("Jam: \(Int(hour.rounded())):00")
                .font(.caption)
                .bold()
        }
        .padding(12)
        .background(Color.black.opacity(0.72))
        .foregroundColor(.white)
        .cornerRadius(14)
        .padding(.top, 50)
        .padding(.horizontal, 12)
    }
}

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

        guard let url = Bundle.main.url(
            forResource: "checkpoint_final_4",
            withExtension: "usda"
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
