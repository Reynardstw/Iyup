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
