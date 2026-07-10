import SwiftUI
import RealityKit
import UIKit

struct ShadeMapView: View {
    /// Lapor ke parent (RootTabView) saat masuk/keluar mode detail (View Details),
    /// supaya tab bar bisa disembunyikan.
    var onDetailActiveChange: (Bool) -> Void = { _ in }

    @State private var viewModel = ShadeMapViewModel()

    // Gesture state tetap di View agar update 60fps tidak membebani ViewModel.
    @State private var lastDrag: CGSize = .zero
    @State private var lastMag: CGFloat = 1
    @State private var lastPan: CGSize = .zero
    @State private var lastRotation: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                prewarmView
                backgroundLayer
                lockPlaceholderLayer
                realityMapLayer
                controlUILayer
                planTripLayer
            }
            .onDisappear {
                viewModel.selectedSpot = nil
            }
            .onChange(of: viewModel.hour) { _, newValue in
                viewModel.syncHourChange(newValue)
            }
            .onChange(of: viewModel.selectedDate) { _, newValue in
                viewModel.syncSelectedDateChange(newValue)
            }
            .onChange(of: viewModel.showDetail) { _, newValue in
                onDetailActiveChange(newValue)
            }
            .sheet(isPresented: $viewModel.showSheet) {
                ParkDetailSheetContent(
                    detent: viewModel.sheetDetent,
                    peekDetent: viewModel.peekDetent,
                    largeDetent: viewModel.largeDetent,
                    info: viewModel.parkDetailViewModel.info,
                    onPlanTrip: {
                        viewModel.openPlanTripFromSheet()
                    },
                    onSelectDay: { index in
                        Task { await viewModel.parkDetailViewModel.selectWeekday(index) }
                    }
                )
                .onAppear { print("⏱[sheet] ParkDetailSheetContent onAppear") }
                .presentationDetents(
                    [viewModel.peekDetent, viewModel.midDetent, viewModel.largeDetent],
                    selection: $viewModel.sheetDetent
                )
                .presentationBackgroundInteraction(.enabled(upThrough: viewModel.midDetent))
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
            }
            .task {
                await viewModel.loadParkDetail()
            }
            .navigationDestination(item: $viewModel.selectedTripForEditing) { trip in
                EditTripView(trip: trip)
            }
        }
        .toolbar(viewModel.showDetail ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.25), value: viewModel.showDetail)
    }
}

// MARK: - UI Layers
extension ShadeMapView {
    private var prewarmView: some View {
        VStack(spacing: 0) {
            Color.clear.frame(width: 1, height: 1).background(.thinMaterial)
            Color.clear.frame(width: 1, height: 1).background(.ultraThinMaterial)
            Color.clear.frame(width: 1, height: 1).background(.regularMaterial)
            Text(" ").frame(width: 1, height: 1).glassEffect(in: .circle)
        }
        .frame(width: 1, height: 1)
        .opacity(0.001)
        .allowsHitTesting(false)
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 234/255, green: 238/255, blue: 255/255),
                    .white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 253/255, green: 224/255, blue: 120/255).opacity(0.9),
                    Color(red: 253/255, green: 224/255, blue: 120/255).opacity(0)
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            .opacity(viewModel.showDetail ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showDetail)
        }
        .ignoresSafeArea()
    }

    private var lockPlaceholderLayer: some View {
        ZStack {
            Image(systemName: "map")
                .font(.system(size: 150))
                .padding(40)
                .opacity(0.1)

            Image(systemName: "lock")
                .font(.system(size: 100, weight: .light))
                .foregroundColor(.gray)
        }
        .opacity(viewModel.currentPark.isMapped ? 0 : 1)
        .allowsHitTesting(!viewModel.currentPark.isMapped)
    }

    private var realityMapLayer: some View {
        RealityView { content in
            let t0 = CFAbsoluteTimeGetCurrent()
            let root = await viewModel.scene.build()
            print("⏱[3D] ShadeMap scene.build took \(viewModel.ms(t0))")

            content.add(root)
            viewModel.scene.setSun(hour: viewModel.hour, location: viewModel.parkLocation)

            if let realScene = root.scene {
                viewModel.scene.startGlowLoop(scene: realScene)
            }

            viewModel.shadeMapReady = true
            print("⏱[3D] ShadeMap make done (+\(viewModel.ms(t0)))")
        } update: { _ in
            viewModel.scene.setSun(hour: viewModel.hour, location: viewModel.parkLocation)
        }
        .frame(height: viewModel.mapDisplayMode.isPlanTripMini ? viewModel.planTripMapHeight : nil)
        .clipShape(
            RoundedRectangle(
                cornerRadius: viewModel.mapDisplayMode.isPlanTripMini ? 28 : 0,
                style: .continuous
            )
        )
        .padding(.horizontal, viewModel.mapDisplayMode.isPlanTripMini ? 20 : 0)
        .padding(.top, viewModel.mapDisplayMode.isPlanTripMini ? viewModel.planTripMapTopPadding : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .shadow(
            color: Color.black.opacity(viewModel.mapDisplayMode.isPlanTripMini ? 0.18 : 0),
            radius: viewModel.mapDisplayMode.isPlanTripMini ? 18 : 0,
            x: 0,
            y: viewModel.mapDisplayMode.isPlanTripMini ? 10 : 0
        )
        .ignoresSafeArea(edges: viewModel.mapDisplayMode.isPlanTripMini ? [] : .all)
        .allowsHitTesting(viewModel.showDetail && !viewModel.showPlanTrip && viewModel.currentPark.isMapped)
        .animation(.spring(response: 0.48, dampingFraction: 0.86), value: viewModel.mapDisplayMode)
        .zIndex(viewModel.mapDisplayMode.isPlanTripMini ? 20 : 0)
        .overlay(alignment: .bottomLeading) {
            if viewModel.showDetail && !viewModel.showPlanTrip {
                WeatherBadge(
                    temperatureCelsius: viewModel.parkDetailViewModel.info.temperatureCelsius,
                    symbolName: viewModel.parkDetailViewModel.info.weatherSymbolName
                )
                .padding(.leading, 29)
                .padding(.bottom, viewModel.weatherBadgeBottomPadding)
                .opacity(viewModel.floatingControlsOpacity)
            }
        }
        .overlay {
            if viewModel.showDetail && !viewModel.showPlanTrip {
                TwoFingerPan(
                    onPan: { translation in
                        withAnimation { viewModel.selectedSpot = nil }
                        let dy = Float(translation.height - lastPan.height)
                        viewModel.scene.tilt(dy: dy)
                        lastPan = translation
                    },
                    onEnded: { lastPan = .zero }
                )
            }
        }
        .overlay {
            if !viewModel.showPlanTrip,
               viewModel.selectedSpot != nil,
               let location = viewModel.tapLocation {
                cardPopupOverlay(at: location)
            }
        }
        .gesture((viewModel.showDetail && !viewModel.showPlanTrip) ? tapGesture : nil)
        .simultaneousGesture((viewModel.showDetail && !viewModel.showPlanTrip) ? panGesture : nil)
        .simultaneousGesture((viewModel.showDetail && !viewModel.showPlanTrip) ? rotateGesture : nil)
        .simultaneousGesture((viewModel.showDetail && !viewModel.showPlanTrip) ? zoomGesture : nil)
        .opacity(viewModel.currentPark.isMapped ? 1 : 0)
    }

    private var controlUILayer: some View {
        ZStack {
            if !viewModel.showPlanTrip {
                VStack(spacing: 0) {
                    if viewModel.showDetail {
                        detailTopBar
                    } else {
                        mapHeader
                    }

                    Spacer()

                    if !viewModel.showDetail {
                        carouselChevrons
                    }

                    Spacer()

                    if !viewModel.showDetail {
                        mapFooter
                    }
                }
            }

            if viewModel.showDetail && !viewModel.showPlanTrip {
                HStack {
                    Spacer()
                    TimeSliderPanel(hour: $viewModel.hour)
                        .padding(.trailing, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.bottom, viewModel.timeSliderBottomPadding)
                .opacity(viewModel.floatingControlsOpacity)
                .allowsHitTesting(true)
            }
        }
    }

    @ViewBuilder
    private var planTripLayer: some View {
        if viewModel.showPlanTrip {
            PlanTripView(
                parkName: viewModel.parkDetailViewModel.info.name,
                recommendedShadeWindow: viewModel.parkDetailViewModel.info.recommendedShadeWindow,
                selectedDate: $viewModel.selectedDate,
                viewModel: viewModel.planTripViewModel,
                city: viewModel.parkDetailViewModel.info.city,
                address: viewModel.parkDetailViewModel.info.address,
                mapTopSpacing: viewModel.planTripMapReservedHeight,
                onClose: {
                    viewModel.closePlanTrip()
                },
                onSelectedDateChange: { newDate in
                    viewModel.applyPlanTripDate(newDate)
                },
                onSaveTrip: { trip in
                    viewModel.openSavedTripInEditView(trip)
                }
            )
            .transition(.move(edge: .trailing).combined(with: .opacity))
            .zIndex(10)
        }
    }
}

// MARK: - Reusable UI Components
extension ShadeMapView {
    @ViewBuilder
    private func cardPopupOverlay(at location: CGPoint) -> some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedSpot = nil
                    }
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        withAnimation { viewModel.selectedSpot = nil }
                    }
                )

            ShadeCard()
                .position(location)
                .offset(x: 80, y: -40)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .onTapGesture {}
        }
    }

    private var carouselChevrons: some View {
        HStack {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
                .font(.system(size: 28, weight: .medium))
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { viewModel.previousPark() }
                }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.black)
                .font(.system(size: 28, weight: .medium))
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy) { viewModel.nextPark() }
                }
        }
        .padding(.horizontal, 20)
    }

    private var mapHeader: some View {
        VStack(spacing: 0) {
            Text(viewModel.currentPark.name)
                .font(.system(size: 32, weight: .bold))

            Text(viewModel.currentPark.description)
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 4)

            HStack {
                Image(systemName: "location.fill")
                Text(viewModel.currentPark.distanceInfo)
                    .font(.system(size: 14, weight: .medium))
            }
            .font(.footnote)
        }
        .padding(.top, 60)
    }

    private var detailTopBar: some View {
        HStack {
            Button {
                withAnimation { viewModel.selectedSpot = nil }
                viewModel.closeDetail()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(12)
                    .glassEffect(in: .circle)
            }

            Spacer()

            Button {
                viewModel.showCalendar = true
            } label: {
                Text(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .contentShape(Capsule())
                    .glassEffect(in: .capsule)
            }
            .popover(isPresented: $viewModel.showCalendar) {
                VStack {
                    DatePicker(
                        "Pilih Tanggal",
                        selection: $viewModel.selectedDate,
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

            Image(systemName: "chevron.left")
                .font(.title)
                .padding(12)
                .opacity(0)
        }
        .padding(.horizontal, 16)
    }

    private var mapFooter: some View {
        Button("View Details") {
            viewModel.handleViewDetails()
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.currentPark.isMapped ? Color(red: 153/255, green: 69/255, blue: 236/255) : Color.gray)
        .disabled(!viewModel.currentPark.isMapped)
        .controlSize(.large)
        .padding(.bottom, 30)
    }

    struct WeatherBadge: View {
        let temperatureCelsius: Int
        let symbolName: String

        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.multicolor)

                Text("\(temperatureCelsius)°")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.primary.opacity(0.72))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: Capsule())
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Gestures
extension ShadeMapView {
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                print("tap:", value.entity.name)

                if let spot = viewModel.scene.spotForEntity(value.entity.name) {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedSpot = spot
                        viewModel.tapLocation = value.location
                    }
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectedSpot = nil
                    }
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let dx = Float(value.translation.width - lastDrag.width)
                let dy = Float(value.translation.height - lastDrag.height)
                viewModel.scene.pan(dx: dx, dy: dy)
                lastDrag = value.translation
            }
            .onEnded { _ in
                lastDrag = .zero
            }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { value in
                let delta = Float(value.rotation.radians - lastRotation)
                viewModel.scene.rotate(dx: delta * 100)
                lastRotation = value.rotation.radians
            }
            .onEnded { _ in
                lastRotation = 0
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = Float(value.magnification - lastMag) * 2
                viewModel.scene.zoom(delta: delta)
                lastMag = value.magnification
            }
            .onEnded { _ in
                lastMag = 1
            }
    }
}
