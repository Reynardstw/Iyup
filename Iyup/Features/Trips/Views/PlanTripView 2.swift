import SwiftUI

struct PlanTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PlanTripViewModel
    @Binding private var selectedDate: Date

    let parkName: String
    let recommendedShadeWindow: String
    let city: String
    let address: String

    /// Height reserved for the live 3D map that stays in ShadeMapView.
    /// PlanTrip does not build another RealityView; this clear slot lets the existing
    /// map appear as the preview window.
    private let mapTopSpacing: CGFloat

    private let onClose: (() -> Void)?
    private let onSelectedDateChange: (Date) -> Void
    private let onSaveTrip: ((Trip) -> Void)?

    private let accent = Color(red: 0.60, green: 0.22, blue: 0.92)
    private let pageBackground = Color(red: 0.92, green: 0.94, blue: 1.00)

    init(
        parkName: String,
        recommendedShadeWindow: String,
        selectedDate: Binding<Date>,
        viewModel: PlanTripViewModel,
        city: String = "",
        address: String = "",
        mapTopSpacing: CGFloat = 0,
        onClose: (() -> Void)? = nil,
        onSelectedDateChange: @escaping (Date) -> Void = { _ in },
        onSaveTrip: ((Trip) -> Void)? = nil
    ) {
        self.parkName = parkName
        self.recommendedShadeWindow = recommendedShadeWindow
        self.city = city
        self.address = address
        self.mapTopSpacing = mapTopSpacing
        self.onClose = onClose
        self.onSelectedDateChange = onSelectedDateChange
        self.onSaveTrip = onSaveTrip
        _selectedDate = selectedDate
        _viewModel = State(initialValue: viewModel)
    }

    // Compatibility initializer for old call sites.
    // The scene and scoreViewModel are intentionally ignored because this page
    // should not reload a second RealityKit map.
    init(
        parkName: String,
        recommendedShadeWindow: String,
        scene: ParkScene,
        viewModel: PlanTripViewModel,
        scoreViewModel: MLShadeRecommendationViewModel
    ) {
        self.init(
            parkName: parkName,
            recommendedShadeWindow: recommendedShadeWindow,
            selectedDate: .constant(viewModel.selectedDate),
            viewModel: viewModel,
            mapTopSpacing: 0,
            onClose: nil,
            onSelectedDateChange: { _ in },
            onSaveTrip: nil
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(parkName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 132)

                mapWindowSlot

                shadeConditionSection

                Divider()
                    .padding(.top, 2)

                recommendedHoursRow

                dateTimeSection

                Text("Get notified about the plan")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.top, 6)

                alertSection

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            topBar
        }
        .onAppear {
            viewModel.selectedDate = selectedDate
        }
        .onChange(of: selectedDate) { _, newValue in
            viewModel.selectedDate = newValue
            onSelectedDateChange(newValue)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                close()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: Circle())
            }

            Spacer()

            Text("Plan Your Trip")
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Button("Save") {
                let trip = saveTrip()

                if let onSaveTrip {
                    onSaveTrip(trip)
                } else {
                    close()
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(accent)
            .clipShape(Capsule())
            .glassEffect(.regular, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    @discardableResult
    private func saveTrip() -> Trip {
        let trip = Trip(
            parkName: parkName,
            city: city,
            address: address,
            latitude: viewModel.parkLocation.latitude,
            longitude: viewModel.parkLocation.longitude,
            date: selectedDate,
            recommendedShadeWindow: recommendedShadeWindow,
            alertOption: viewModel.alertOption,
            shadeConditionText: viewModel.shadeConditionText
        )
        TripStore.shared.add(trip)
        Task { await TripNotificationScheduler.schedule(for: trip) }
        return trip
    }

    private var mapWindowSlot: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: max(120, mapTopSpacing))
            .padding(.horizontal, 8)
            .accessibilityHidden(true)
    }

    private var shadeConditionSection: some View {
        Text("Shade condition is based on your selected date and time")
            .font(.caption2)
            .foregroundStyle(.primary.opacity(0.85))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
    }

    private var recommendedHoursRow: some View {
        HStack(spacing: 8) {
            Text("Recommended hours:")
                .font(.subheadline)
                .foregroundStyle(.primary)

            Text(recommendedShadeWindow)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
    }

    private var dateTimeSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "calendar.badge.clock")
                Text("Date & Time")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.primary)

            Spacer(minLength: 8)

            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)

            DatePicker(
                "Time",
                selection: $selectedDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }
    }

    private var alertSection: some View {
        HStack {
            Text("Alert")
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Picker("Alert", selection: $viewModel.alertOption) {
                ForEach(TripAlertOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.secondary)
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

#Preview {
    let bundle = AppComposition.makePlanTripBundle()
    PlanTripView(
        parkName: "Taman Bendera Pusaka",
        recommendedShadeWindow: "16.00 - 18.00",
        selectedDate: .constant(Date()),
        viewModel: bundle.planTripViewModel,
        mapTopSpacing: 150
    )
}
