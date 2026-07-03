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
        let f = dayFactor

        let top = Color(
            red: 0.05 + 0.35 * f,
            green: 0.07 + 0.45 * f,
            blue: 0.12 + 0.55 * f
        )

        let bottom = Color(
            red: 0.03 + 0.20 * f,
            green: 0.04 + 0.28 * f,
            blue: 0.08 + 0.38 * f
        )

        return LinearGradient(
            colors: [top, bottom],
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

    /// Penting:
    /// Kode lama kamu memakai:
    /// z = -cos(alt) * cos(az)
    ///
    /// Jadi di logic baru kita pakai `.northNegative`
    /// agar arah visual matahari tetap konsisten dengan scene lama.
    ///
    /// Kalau nanti arah bayangan kebalik, ubah ke `.northPositive`.
    private let sunVectorConverter = SunVectorConverter(
        zAxisDirection: .northNegative
    )

    func build() async -> Entity {
        container.addChild(worldRoot)

        sunLight.light.color = .white
        sunLight.shadow = DirectionalLightComponent.Shadow(
            maximumDistance: 8,
            depthBias: 1.0
        )
        container.addChild(sunLight)

        fillLight.light.color = .white
        fillLight.look(
            at: [0, 0, 0],
            from: [-3, 6, -2],
            relativeTo: nil
        )
        container.addChild(fillLight)

        guard let url = Bundle.main.url(
            forResource: "checkpoint_final_4",
            withExtension: "usda"
        ) else {
            print("checkpoint1.usda tidak ditemukan di bundle")
            return container
        }

        do {
            let park = try await Entity(contentsOf: url)
            worldRoot.addChild(park)

            let bounds = park.visualBounds(relativeTo: worldRoot)
            let center = bounds.center
            let extents = bounds.extents

            addTrees(
                boundsMin: bounds.min,
                boundsMax: bounds.max,
                groundY: bounds.min.y
            )

            let longest = max(extents.x, extents.z)
            let scale = longest > 0 ? (6.0 / longest) : 1.0

            worldRoot.scale = [scale, scale, scale]
            worldRoot.position = -center * scale
            targetWorld = .zero
        } catch {
            print("Gagal load checkpoint1.usda: \(error.localizedDescription)")
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

        if sun.altitudeDegrees <= 0 {
            sunLight.light.intensity = 0
        } else {
            sunLight.light.intensity = 500 + 2300 * altitudeFactor

            let sunDirection = sunVectorConverter.directionVector(
                from: sun
            )

            sunLight.look(
                at: targetWorld,
                from: targetWorld + sunDirection,
                relativeTo: nil
            )
        }

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

    private func addTrees(
        boundsMin: SIMD3<Float>,
        boundsMax: SIMD3<Float>,
        groundY: Float
    ) {
        let fractions: [(Float, Float)] = [
            (0.45, 0.08), (0.55, 0.14), (0.42, 0.20), (0.58, 0.26),
            (0.40, 0.33), (0.60, 0.39), (0.44, 0.46), (0.56, 0.52),
            (0.38, 0.58), (0.62, 0.64), (0.46, 0.70), (0.54, 0.76),
            (0.42, 0.82), (0.58, 0.88), (0.50, 0.94),
            (0.35, 0.30), (0.65, 0.50), (0.33, 0.66), (0.67, 0.78)
        ]

        let sizeX = boundsMax.x - boundsMin.x
        let sizeZ = boundsMax.z - boundsMin.z

        for (index, fraction) in fractions.enumerated() {
            let x = boundsMin.x + sizeX * fraction.0
            let z = boundsMin.z + sizeZ * fraction.1

            let height = Float.random(in: 12...24)
            let trunkRadius = Float.random(in: 0.20...0.45)
            let crownRadius = max(height * 0.34, 1.2)

            let tree = Entity()
            tree.name = String(format: "Pohon_%02d", index + 1)

            let trunkHeight = height * 0.50

            let trunk = ModelEntity(
                mesh: .generateCylinder(
                    height: trunkHeight,
                    radius: trunkRadius
                ),
                materials: [
                    SimpleMaterial(
                        color: .brown,
                        roughness: 0.9,
                        isMetallic: false
                    )
                ]
            )
            trunk.position = [0, trunkHeight / 2, 0]

            let crown = ModelEntity(
                mesh: .generateSphere(radius: crownRadius),
                materials: [
                    SimpleMaterial(
                        color: .init(
                            red: 0.22,
                            green: 0.55,
                            blue: 0.22,
                            alpha: 1
                        ),
                        roughness: 0.95,
                        isMetallic: false
                    )
                ]
            )
            crown.position = [0, trunkHeight + crownRadius * 0.75, 0]

            tree.addChild(trunk)
            tree.addChild(crown)
            tree.position = [x, groundY, z]

            worldRoot.addChild(tree)
        }
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
