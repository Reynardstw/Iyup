import SwiftUI
import RealityKit

struct ShadeMapView: View {
    @State private var hour: Double = 10
    @State private var scene = ParkScene()

    @State private var lastDrag: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1.0

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
            .ignoresSafeArea()
            .gesture(orbitGesture)
            .simultaneousGesture(zoomGesture)

            controls
        }
    }

    private var orbitGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let deltaX = Float(value.translation.width - lastDrag.width)
                let deltaY = Float(value.translation.height - lastDrag.height)
                lastDrag = value.translation

                scene.rotateCamera(
                    deltaAzimuth: -deltaX * 0.01,
                    deltaElevation: deltaY * 0.01
                )
            }
            .onEnded { _ in
                lastDrag = .zero
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let ratio = Float(value.magnification / lastMagnification)
                lastMagnification = value.magnification
                scene.zoomCamera(scale: ratio)
            }
            .onEnded { _ in
                lastMagnification = 1.0
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Taman Bendera Pusaka 3D")
                .font(.subheadline)
                .bold()

            Text(
                String(
                    format: "Jam %02d:00 | Alt %.1f° | Az %.1f°",
                    Int(hour.rounded()),
                    sun.altitudeDegrees,
                    sun.azimuthDegrees
                )
            )
            .font(.caption2)

            HStack(spacing: 8) {
                Text("06")
                    .font(.caption2)

                Slider(value: $hour, in: 6...18, step: 1)

                Text("18")
                    .font(.caption2)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.72))
        .foregroundColor(.white)
        .cornerRadius(14)
        .frame(maxWidth: 260)
        .padding(.top, 8)
        .padding(.horizontal, 12)
    }
}
