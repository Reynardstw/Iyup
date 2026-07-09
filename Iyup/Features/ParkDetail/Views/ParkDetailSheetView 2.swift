import SwiftUI

struct ParkDetailSheetView: View {
    @State private var viewModel: ParkDetailViewModel

    private let peekDetent = PresentationDetent.height(73)
    private let midDetent = PresentationDetent.fraction(0.5)
    private let largeDetent = PresentationDetent.large

    @State private var detent: PresentationDetent = .height(73)
    @State private var showPlanTrip = false
    @State private var isReady = false

    init(viewModel: ParkDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init() {
        _viewModel = State(initialValue: AppComposition.makeParkDetailViewModel())
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationDestination(isPresented: $showPlanTrip) {
                    PlanTripView(
                        parkName: viewModel.info.name,
                        recommendedShadeWindow: viewModel.info.recommendedShadeWindow
                    )
                }
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            mapPlaceholder
            backButton
            debugHourSlider
        }
        .sheet(isPresented: $isReady) {
            ParkDetailSheetContent(
                detent: detent,
                peekDetent: peekDetent,
                largeDetent: largeDetent,
                info: viewModel.info,
                onPlanTrip: {
                    isReady = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showPlanTrip = true
                    }
                },
                onSelectDay: { index in
                    Task { await viewModel.selectWeekday(index) }
                }
            )
            .presentationDetents([peekDetent, midDetent, largeDetent], selection: $detent)
            .presentationBackgroundInteraction(.enabled(upThrough: midDetent))
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(50))
            isReady = true
            await viewModel.load()
        }
    }

    private var debugHourSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Debug jam: \(viewModel.selectedHour).00")
                .font(.caption.bold())

            Slider(
                value: Binding(
                    get: { Double(viewModel.selectedHour) },
                    set: { viewModel.selectedHour = Int($0.rounded()) }
                ),
                in: 6...18,
                step: 1
            )
            .frame(width: 220)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.leading, 16)
        .padding(.top, 60)
    }

    private var warmUpView: some View {
        VStack {
            Color.clear.background(.ultraThinMaterial)
            Color.clear.background(.regularMaterial)
        }
        .frame(width: 1, height: 1)
        .opacity(0.001)
        .allowsHitTesting(false)
    }

    private var backButton: some View {
        Button {
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .glassEffect(.regular, in: Circle())
        }
        .padding(.leading, 16)
        .padding(.top, 8)
    }

    private var mapPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 234/255, green: 238/255, blue: 255/255),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 40)
                .fill(Color(red: 0.52, green: 0.70, blue: 0.45))
                .frame(width: 150, height: 380)
                .rotationEffect(.degrees(8))
                .overlay(
                    Capsule()
                        .fill(Color(red: 0.55, green: 0.75, blue: 0.92))
                        .frame(width: 14, height: 300)
                        .rotationEffect(.degrees(8))
                )
                .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ParkDetailSheetView(
        viewModel: ParkDetailViewModel(
            place: .tamanBenderaPusaka,
            parkLocation: SunExposureProjectionExporter.tamanBenderaPusakaLocation,
            spots: SunExposureProjectionExporter.benchSpots,
            calculator: ShadowIntervalCalculator(
                sunPositionService: OfficialSunKitSunPositionService(),
                shadowRaycastService: GeometryShadowRaycastService(
                    occluders: SunExposureProjectionExporter.treeOccluders
                ),
                sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive)
            ),
            forecastService: MLShadeMockEnvironmentForecastService(),
            locationViewModel: LocationDistanceViewModel(
                locationService: PreviewUserLocationService(),
                destination: .tamanBenderaPusaka
            ),
            weatherService: PreviewWeatherService()
        )
    )
}
