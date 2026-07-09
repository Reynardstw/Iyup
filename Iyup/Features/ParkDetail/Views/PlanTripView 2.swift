import SwiftUI
import RealityKit

struct PlanTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlanTripViewModel
    @State private var scene = ParkScene()

    let parkName: String
    let recommendedShadeWindow: String

    private let accent = Color(red: 0.49, green: 0.36, blue: 0.96)

    init(
        parkName: String,
        recommendedShadeWindow: String,
        viewModel: PlanTripViewModel
    ) {
        self.parkName = parkName
        self.recommendedShadeWindow = recommendedShadeWindow
        _viewModel = State(initialValue: viewModel)
    }

    init(parkName: String, recommendedShadeWindow: String) {
        self.init(
            parkName: parkName,
            recommendedShadeWindow: recommendedShadeWindow,
            viewModel: AppComposition.makePlanTripViewModel()
        )
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
    
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(parkName)
                    .font(.largeTitle.bold())

                Text("Recommended hours for optimal shade at \(recommendedShadeWindow)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                dateTimeSection
                lockedMap

                VStack(spacing: 6) {
                    Text("Shade condition based on your selected time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(viewModel.shadeConditionText)
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                alertSection
            }
            .padding(20)
        }
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Plan Your Trip")
                    .font(.headline)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    dismiss()
                }
                .buttonStyle(.glassProminent)
                .tint(accent)
            }
        }
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                Text("Date & Time")
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 12) {
                DatePicker(
                    "",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                DatePicker(
                    "",
                    selection: $viewModel.selectedDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.compact)

                Spacer()
            }
        }
    }

    private var lockedMap: some View {
        RealityView { content in
            let root = await scene.build()
            content.add(root)

            scene.setSun(
                hour: Calendar.current.component(.hour, from: viewModel.selectedDate),
                location: viewModel.parkLocation
            )
        } update: { _ in
            scene.setSun(
                hour: Calendar.current.component(.hour, from: viewModel.selectedDate),
                location: viewModel.parkLocation
            )
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .allowsHitTesting(false)
    }

    private var alertSection: some View {
        HStack {
            Text("Alert")
                .font(.body)

            Spacer()

            Picker("Alert", selection: $viewModel.alertOption) {
                ForEach(TripAlertOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        PlanTripView(
            parkName: "Taman Bendera Pusaka",
            recommendedShadeWindow: "16.00 - 18.00",
            viewModel: PlanTripViewModel(
                parkLocation: SunExposureProjectionExporter.tamanBenderaPusakaLocation,
                spots: SunExposureProjectionExporter.benchSpots,
                calculator: ShadowIntervalCalculator(
                    sunPositionService: OfficialSunKitSunPositionService(),
                    shadowRaycastService: GeometryShadowRaycastService(
                        occluders: SunExposureProjectionExporter.treeOccluders
                    ),
                    sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive)
                )
            )
        )
    }
}
