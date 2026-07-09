import SwiftUI
import RealityKit

struct ShadeMapView: View {
    @State private var hour: Double = 10
    @State private var scene = ParkScene()
    @State private var showDetail = false
    
    // gestures
    @State private var lastDrag: CGSize = .zero
    @State private var lastMag: CGFloat = 1
    @State private var lastPan: CGSize = .zero
    @State private var lastRotation: Double = 0
    @State private var isTwoFinger = false
    
    // calender
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    
    // pi
    @State private var selectedSpot: ShadeSpot?
    @State private var tapLocation: CGPoint? = nil
    @State private var selectedPin: Entity? = nil
    
    // hubungin ke ML
    @State private var viewModel = AppComposition.makeScoreViewModel()
    
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
                // Scene.setSun(hour: Int(hour.rounded()), location: parkLocation) -> ganti ke per 15 menit
                scene.setSun(hour: hour, location: parkLocation)
                if let realScene = root.scene {
                    scene.startGlowLoop(scene: realScene)
                }
            } update: { _ in
                // scene.setSun(hour: Int(hour.rounded()), location: parkLocation)
                scene.setSun(hour: hour, location: parkLocation)
            }
            .ignoresSafeArea()
            .overlay(alignment: .bottomLeading) {
                if showDetail{
                    WeatherBadge()
                        .padding(.leading, 20)
                        .padding(.bottom, 40)
                }
            }
            .overlay {
                if showDetail {
                    TwoFingerPan(
                        onPan: { t in
                            withAnimation { selectedSpot = nil }
                            let dy = Float(t.height - lastPan.height)
                            scene.tilt(dy: dy)
                            lastPan = t
                        },
                        onEnded: { lastPan = .zero }
                    )
                }
            }
            .overlay {
                if selectedSpot != nil, let location = tapLocation {
                    ZStack {
                        Color.black.opacity(0.001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedSpot = nil
                                }
                            }
                            .simultaneousGesture(
                                DragGesture().onChanged { _ in
                                    withAnimation { selectedSpot = nil }
                                }
                            )
                        
                        ShadeCard()
                            .position(location)
                            .offset(x: 80, y: -40)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .onTapGesture {
                                // biar tetap kebuka saat pencet popup nya
                            }
                    }
                }
            }
            .gesture(showDetail ? tapGesture : nil)
            .simultaneousGesture(showDetail ? panGesture : nil)
            .simultaneousGesture(showDetail ? rotateGesture : nil)
            .simultaneousGesture(showDetail ? zoomGesture : nil)

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
                            .foregroundColor(.black)
                            .font(.system(size: 28, weight: .medium))
                            .padding(.horizontal, 20)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                            .font(.system(size: 28, weight: .medium))
                            .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                if !showDetail {
                    mapFooter
                }
            }
            
            if showDetail {
                HStack {
                    Spacer()
                    TimeSliderPanel(hour: $hour)
                        .padding(.trailing, 16)
                }
            }
            
        }
        .onDisappear {
            selectedSpot = nil
        }
        .onChange(of: hour) { _, newValue in
            Task { await recalcAndGlow(for: newValue, date: selectedDate) }
        }
        .onChange(of: selectedDate) { _, newValue in
            if showDetail {
                Task { await recalcAndGlow(for: hour, date: newValue) }
            }
        }
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                print("tap:", value.entity.name)
                
                if let spot = scene.spotForEntity(value.entity.name) {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedSpot = spot
                        // Simpan koordinat 2D layar saat pin ditekan
                        tapLocation = value.location
                    }
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedSpot = nil
                    }
                }
            }
    }
    
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
    
    private func tutupPopup() {
        if selectedSpot != nil {
            withAnimation(.spring(duration: 0.3)) {
                selectedSpot = nil
            }
        }
    }
    
    struct WeatherBadge: View {
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 16))
                Text("32°")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
    }
    
    private var mapHeader: some View {
        VStack(spacing: 0) {
            Text("Taman Bendera Pusaka")
                .font(.system(size: 32, weight: .bold))
            Text("South Jakarta | FREE | Open 24 hour")
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 4)
            HStack {
                Image(systemName: "location.fill")
                Text("31km from you • ETA 1h 2m")
                    .font(.system(size: 14, weight: .medium))
            }
            .font(.footnote)
        }
        .padding(.top, 60)
    }
    
    private var detailTopBar: some View {
        HStack {
            Button {
                withAnimation { selectedSpot = nil }
                scene.hideShadeSpots()
                scene.moveCamera(to: [3, 6, 3.5], target: [-0.5, -0.75, 0], duration: 1.0)
                showDetail = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(12)
                    .glassEffect(in: .circle)
            }
            
            Spacer()
            
            Button {
                showCalendar = true
            } label: {
                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .contentShape(Capsule())
                    .glassEffect(in: .capsule)
            }
            .popover(isPresented: $showCalendar) {
                VStack {
                    DatePicker(
                        "Pilih Tanggal",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
                .labelsHidden()
                .datePickerStyle(.graphical)
                .scaleEffect(0.85)
                .padding(2)
                .frame(width: 280, height: 250)
                .presentationCompactAdaptation(.popover)
            }
            
            Spacer()
            
            // placeholder ga keliatan di kanan
            Image(systemName: "chevron.left")
                .font(.title)
                .padding(12)
                .opacity(0)
        }
        .padding(.horizontal, 16)
    }
    
    private func recalcAndGlow(for sliderValue: Double, date: Date) async {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        
        let h = Int(sliderValue)
        let m = Int((sliderValue - Double(h)) * 60)   // 0.25 → 15 menit
        
        // PERBAIKAN: Gunakan parameter 'date', bukan 'Date()' (hari ini)
        guard let start = cal.date(bySettingHour: h, minute: m, second: 0, of: date) else { return }
        let end = start.addingTimeInterval(15 * 60)   // segmen 15 menit
        
        viewModel.startDate = start
        viewModel.endDate = end
        viewModel.stepMinutes = 15
        
        await viewModel.calculate()
        
        let safe = Set(
            viewModel.shadowResults
                .filter { $0.safetyStatus == .fullySafe || $0.safetyStatus == .recommended }
                .map { $0.spot.id }
        )
        
        scene.updateGlow(safeSpotIDs: safe)
    }
    
    private var mapFooter: some View {
        Button("View Details") {
            let now = Date()
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "Asia/Jakarta")!
            
            let comp = cal.dateComponents([.hour, .minute], from: now)
            let currentHour = comp.hour ?? 0
            let currentMinute = comp.minute ?? 0
            
            let totalMinutes = (currentHour * 60) + currentMinute
            let roundedMinutes = Int((Double(totalMinutes) / 15.0).rounded()) * 15
            
            let finalHour = roundedMinutes / 60
            let finalMinute = roundedMinutes % 60
            
            guard let roundedDate = cal.date(bySettingHour: finalHour, minute: finalMinute, second: 0, of: now) else { return }
            
            let currentHourSlider = Double(finalHour) + (Double(finalMinute) / 60.0)
            
            selectedDate = roundedDate
            hour = currentHourSlider
            
            scene.moveCamera(to: [1.2, 3.5, 4.5], target: [0, -1.0, 0], duration: 1.0)
            scene.syncController(position: [1.2, 3.5, 4.5], target: [0, -1.0, 0])
            scene.showShadeSpots()
            showDetail = true
            Task { await recalcAndGlow(for: currentHourSlider, date: roundedDate) }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 153/255, green: 69/255, blue: 236/255))
        .controlSize(.large)
        .padding(.bottom, 30)
    }
    
    private var sun: SunPosition {
        //scene.sunPosition(hour: Int(hour.rounded()), location: parkLocation)
        scene.sunPosition(hour: hour, location: parkLocation)
    }
}
