
//  RealityView { content in
//                let root = await scene.build()
//                content.add(root)
//                scene.setSun(hour: Int(hour.rounded()), location: parkLocation)
//            } update: { _ in
//                scene.setSun(hour: Int(hour.rounded()), location: parkLocation)
//            }
//            .ignoresSafeArea()
//            .gesture(
//                SpatialTapGesture()
//                    .targetedToAnyEntity()
//                    .onEnded { value in
//                        if let worldPos = scene.worldPositionForEntity(value.entity.name) {
////                            let dir = normalize(SIMD3<Float>(0.5, 7, 2) - SIMD3<Float>(0, -1.5, 0))
////                            let newPos = worldPos + dir * 1.5
////                            scene.moveCamera(to: newPos, target: worldPos, duration: 1.0)
//                            scene.focusOn(worldPos)
//                        }
//                    }
//            )
//            .gesture(showDetail ? dragGesture : nil)
//            .gesture(showDetail ? magnifyGesture : nil)
//
//    private var detailTopBar: some View {
//        HStack {
//            Button {
//                scene.moveCamera(to: [3, 6, 3.5], target: [-0.5, -0.75, 0], duration: 1.0)
//                showDetail = false
//                scene.hideShadeSpots()
//            } label: {
//                Image(systemName: "chevron.left")
//                    .font(.title)
//                    .foregroundColor(.white)
//                    .padding(12)
//                    .background(Color.black.opacity(0.5))
//                    .clipShape(Circle())
//            }
//            Spacer()
//        }
//        .padding(.horizontal, 16)
//        .padding(.top, 60)
//        .padding(.bottom, 20)
//    }
//
//    private var mapFooter: some View {
//        Button("View Details") {
//            scene.moveCamera(to: [0.5, 7, 2], target: [0, -1.5, 0], duration: 1.0)
//            scene.showShadeSpots(forHour: Int(hour.rounded()))
//            showDetail = true
//
//        }
//        .buttonStyle(.borderedProminent)
//        .tint(.purple)
//        .controlSize(.large)
//        .padding(.bottom, 30)
//    }

import SwiftUI
import RealityKit

struct ShadeMapView: View {
    @State private var hour: Double = 10
    @State private var scene = ParkScene()
    @State private var showDetail = false
    
    @State private var lastDrag: CGSize = .zero
    @State private var lastMag: CGFloat = 1
    @State private var lastPan: CGSize = .zero
    
    @State private var lastRotation: Double = 0
    
    @State private var isTwoFinger = false
    
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    
    private let parkLocation = ParkLocation(
        latitude: -6.245542,
        longitude: 106.794547,
        timeZoneIdentifier: "Asia/Jakarta"
    )
    
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 234/255, green: 238/255, blue: 255/255),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            RealityView { content in
                let root = await scene.build()
                content.add(root)
                scene.setSun(hour: Int(hour.rounded()), location: parkLocation)
            } update: { _ in
                scene.setSun(hour: Int(hour.rounded()), location: parkLocation)
            }
            .ignoresSafeArea()
            .overlay {
                if showDetail {
                    TwoFingerPan(
                        onPan: { t in
                            let dy = Float(t.height - lastPan.height)
                            scene.tilt(dy: dy)
                            lastPan = t
                        },
                        onEnded: { lastPan = .zero }
                    )
                }
            }
            .simultaneousGesture(showDetail ? panGesture : nil)
            .simultaneousGesture(showDetail ? rotateGesture : nil)
            .simultaneousGesture(showDetail ? zoomGesture : nil)
            .simultaneousGesture(showDetail ? tapGesture : nil)
            
            //            VStack(spacing: 0) {
            //                if showDetail {
            //                    detailTopBar
            //                } else {
            //                    mapHeader
            //                }
            //
            //                Spacer()
            //
            //                if !showDetail {
            //                    HStack {
            //                        Image(systemName: "chevron.left")
            //                            .font(.title)
            //                            .foregroundColor(.black)
            //                        Spacer()
            //                        Image(systemName: "chevron.right")
            //                            .font(.title)
            //                            .foregroundColor(.black)
            //                    }
            //                    .padding(.horizontal, 20)
            //                }
            //
            //                Spacer()
            //
            //                if showDetail {
            //                    sliderCard
            //                        .padding(.horizontal, 16)
            //                        .padding(.bottom, 40)
            //                } else {
            //                    mapFooter
            //                }
            //            }
            //        }
            //    }
            
            VStack(spacing: 0) {
                if showDetail {
                    detailTopBar
                } else {
                    mapHeader
                }
                
                Spacer()
                
                if !showDetail {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                if !showDetail {
                    mapFooter
                }
            }
            
            // slider vertikal, muncul saat detail
            if showDetail {
                HStack {
                    Spacer()
                    TimeSliderPanel(hour: $hour)
                        .padding(.trailing, 16)
                }
            }
        }
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                print("tap kena:", value.entity.name)
                if let worldPos = scene.worldPositionForEntity(value.entity.name) {
                    scene.focusPin(worldPos)
                }
            }
    }
    
    private var mapHeader: some View {
        VStack(spacing: 0) {
            Text("Taman Bendera Pusaka")
                .font(.system(size: 32, weight: .bold))
            Text("South Jakarta | FREE | Open 24 hour")
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 6)
            
            
            HStack {
                Image(systemName: "location.fill")
                Text("31km from you • ETA 1h 2m")
                    .font(.system(size: 14, weight: .medium))
            }
            .font(.footnote)
            //            .padding(.horizontal, 16)
            //            .padding(.vertical, 8)
        }
        .padding(.top, 60)
    }
    
    private var detailTopBar: some View {
            HStack {
                // 1. Tombol Back di Kiri
                Button {
                    scene.hideShadeSpots()
    //                scene.resetCamera()
                    scene.moveCamera(to: [3, 6, 3.5], target: [-0.5, -0.75, 0], duration: 1.0)
                    showDetail = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(.black)
                        .padding(12)
                        .glassEffect(in: .circle)
                }
                
                Spacer() // Mendorong tanggal ke tengah
                
                // 2. Tanggal Liquid Glass di Tengah
                Button {
                    showCalendar = true
                } label: {
                    // PERBAIKAN: Gunakan selectedDate agar teks berubah saat kalender dipilih
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        // PERBAIKAN: Membuat seluruh area kapsul responsif saat disentuh
                        .contentShape(Capsule())
                        .glassEffect(in: .capsule)
                }
                .popover(isPresented: $showCalendar) {
                    // PERBAIKAN: Bungkus di dalam VStack untuk memberikan ukuran tetap
                    VStack {
                        DatePicker(
                            "Pilih Tanggal",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                    .padding()
                    // PERBAIKAN: Kunci ukuran popover agar kalender tidak gepeng
                    .frame(width: 320, height: 350)
                    .presentationCompactAdaptation(.popover)
                }
                
                Spacer() // Mendorong tanggal ke tengah dari arah kanan
                
                // 3. Placeholder transparan di Kanan
                Image(systemName: "chevron.left")
                    .font(.title)
                    .padding(12)
                    .opacity(0)
            }
            .padding(.horizontal, 16)
    //        .padding(.top, 40)
        }
    
    private var mapFooter: some View {
        Button("View Details") {
            //            scene.resetCamera()
            //            scene.moveCamera(to: [0.5, 7, 2], target: [0, -1.5, 0], duration: 1.0)
            scene.moveCamera(to: [0.5, 7, 2], target: [0, -1.5, 0], duration: 1.0)
            scene.syncController(position: [0.5, 7, 2], target: [0, -1.5, 0])
            scene.showShadeSpots(forHour: Int(hour.rounded()))
            showDetail = true
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 153/255, green: 69/255, blue: 236/255))
        .controlSize(.large)
        .padding(.bottom, 30)
    }
    
    private var sun: SunPosition {
        scene.sunPosition(hour: Int(hour.rounded()), location: parkLocation)
    }
    
    //    private var sliderCard: some View {
    //        VStack(alignment: .leading, spacing: 10) {
    //            Text("Taman Bendera Pusaka 3D")
    //                .font(.headline)
    //            Text("Tanggal demo: 7 Mar 2026")
    //                .font(.caption2).opacity(0.85)
    //            Text(String(format: "Jam %02d:00 | Alt %.1f° | Az %.1f°",
    //                        Int(hour.rounded()), sun.altitudeDegrees, sun.azimuthDegrees))
    //                .font(.caption)
    //
    //            HStack {
    //                Text("06").font(.caption)
    //                Slider(value: $hour, in: 6...18, step: 1)
    //                Text("18").font(.caption)
    //            }
    //
    //            Text("Jam: \(Int(hour.rounded())):00")
    //                .font(.caption).bold()
    //        }
    //        .padding(12)
    //        .background(Color.black.opacity(0.72))
    //        .foregroundColor(.white)
    //        .cornerRadius(14)
    //    }
    
    // 1 jari = PAN
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let dx = Float(value.translation.width - lastDrag.width)
                let dy = Float(value.translation.height - lastDrag.height)
                scene.pan(dx: dx, dy: dy)
                lastDrag = value.translation
            }
            .onEnded { _ in lastDrag = .zero }
    }
    //
    // 2 jari rotate = putar
    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                let delta = Float(value.rotation.radians - lastRotation)
                scene.rotate(dx: delta * 100)
                lastRotation = value.rotation.radians
            }
            .onEnded { _ in lastRotation = 0 }
    }
    
    // 2 jari pinch = zoom
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = Float(value.magnification - lastMag) * 2
                scene.zoom(delta: delta)
                lastMag = value.magnification
            }
            .onEnded { _ in lastMag = 1 }
    }
    
    //    private var tapGesture: some Gesture {
    //        SpatialTapGesture()
    //            .targetedToAnyEntity()
    //            .onEnded { value in
    //                if let worldPos = scene.worldPositionForEntity(value.entity.name) {
    //                    scene.focusPin(worldPos)
    //                }
    //            }
    //    }
    
    //    private var panGesture: some Gesture {
    //        DragGesture(minimumDistance: 8)
    //            .onChanged { value in
    //                if isTwoFinger { return }
    //                let dx = Float(value.translation.width - lastDrag.width)
    //                let dy = Float(value.translation.height - lastDrag.height)
    //                scene.pan(dx: dx, dy: dy)
    //                lastDrag = value.translation
    //            }
    //            .onEnded { _ in lastDrag = .zero }
    //    }
    
    //    private var zoomGesture: some Gesture {
    //        MagnifyGesture()
    //            .onChanged { value in
    //                let delta = Float(value.magnification - lastMag) * 4
    //                scene.zoom(delta: delta)
    //                lastMag = value.magnification
    //            }
    //            .onEnded { _ in lastMag = 1 }
    //    }
}
