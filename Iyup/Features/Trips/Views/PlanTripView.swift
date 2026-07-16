import SwiftUI

struct PlanTripView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PlanTripViewModel
    @Binding private var selectedDate: Date

    let parkName: String
    let recommendedShadeWindow: String
    let city: String
    let address: String

    private let mapTopSpacing: CGFloat

    private let editingTrip: Trip?

    private let onClose: (() -> Void)?
    private let onSelectedDateChange: (Date) -> Void
    private let onSaveTrip: ((Trip) -> Void)?

    private let pageBackground = Color(.systemGroupedBackground)

    init(
        parkName: String,
        recommendedShadeWindow: String,
        selectedDate: Binding<Date>,
        viewModel: PlanTripViewModel,
        city: String = "",
        address: String = "",
        mapTopSpacing: CGFloat = 0,
        editingTrip: Trip? = nil,
        onClose: (() -> Void)? = nil,
        onSelectedDateChange: @escaping (Date) -> Void = { _ in },
        onSaveTrip: ((Trip) -> Void)? = nil
    ) {
        self.parkName = parkName
        self.recommendedShadeWindow = recommendedShadeWindow
        self.city = city
        self.address = address
        self.mapTopSpacing = mapTopSpacing
        self.editingTrip = editingTrip
        self.onClose = onClose
        self.onSelectedDateChange = onSelectedDateChange
        self.onSaveTrip = onSaveTrip
        _selectedDate = selectedDate
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(parkName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 80)

                mapPreviewWindow

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

            if let editingTrip {
                viewModel.alertOption = editingTrip.alertOption
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            viewModel.selectedDate = newValue
            onSelectedDateChange(newValue)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Custom header: this screen is a HUD overlay above the live map,
    /// outside any navigation context, so the system navigation bar cannot
    /// appear here. Patched for accessibility and Dynamic Type.
    private var topBar: some View {
        ZStack {
            Text(editingTrip == nil ? "Plan Your Trip" : "Edit Trip")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button {
                    close()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    let trip = saveTrip()
                    if let onSaveTrip {
                        onSaveTrip(trip)
                    } else {
                        close()
                    }
                } label: {
                    Text("Save")
                        .font(.body.weight(.semibold))
                        .frame(height: 44)
                        .padding(.horizontal, 18)
                        .contentShape(Capsule())
                        .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal, 16)
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
            id: editingTrip?.id ?? UUID(),
            parkName: parkName,
            city: city,
            address: address,
            latitude: viewModel.parkLocation.latitude,
            longitude: viewModel.parkLocation.longitude,
            date: selectedDate,
            recommendedShadeWindow: recommendedShadeWindow,
            alertOption: viewModel.alertOption,
            shadeConditionText: viewModel.shadeConditionText,
            savedAt: editingTrip?.savedAt ?? Date()
        )

        if editingTrip == nil {
            TripStore.shared.add(trip)
            Task { await TripNotificationScheduler.schedule(for: trip) }
        } else {
            TripStore.shared.update(trip)
        }

        return trip
    }

    @ViewBuilder
    private var mapPreviewWindow: some View {
        if mapTopSpacing > 0 {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: mapTopSpacing)
                .padding(.horizontal, 8)
                .accessibilityHidden(true)
        } else {
            StandalonePark3DPreview(
                location: previewParkLocation,
                hour: selectedHour,
                highlightedSpotIDs: viewModel.shadedSpotIDs
            )
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 8)
        }
    }

    private var previewParkLocation: ParkLocation {
        if let editingTrip {
            return ParkLocation(
                latitude: editingTrip.latitude,
                longitude: editingTrip.longitude,
                timeZoneIdentifier: viewModel.parkLocation.timeZoneIdentifier
            )
        }

        return viewModel.parkLocation
    }

    private var selectedHour: Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = previewParkLocation.timeZone

        let components = calendar.dateComponents([.hour, .minute], from: selectedDate)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0) / 60.0
        return hour + minute
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
    PlanTripView(
        parkName: "Taman Bendera Pusaka",
        recommendedShadeWindow: "16.00 - 18.00",
        selectedDate: .constant(Date()),
        viewModel: AppComposition.makePlanTripViewModel(),
        mapTopSpacing: 150
    )
}
