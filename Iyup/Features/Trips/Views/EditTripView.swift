import SwiftUI
import MapKit
import CoreLocation

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var selectedDate: Date
    @State private var alertOption: TripAlertOption
    @State private var shadeConditionText: String
    @State private var position: MapCameraPosition
    @State private var showPlanTrip = false
    @State private var planTripViewModel = AppComposition.makePlanTripViewModel()

    private let pageBackground = Color(red: 0.92, green: 0.94, blue: 1.00)

    init(trip: Trip) {
        self.trip = trip
        _selectedDate = State(initialValue: trip.date)
        _alertOption = State(initialValue: trip.alertOption)
        _shadeConditionText = State(initialValue: trip.shadeConditionText)
        _position = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: trip.latitude,
                        longitude: trip.longitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.005,
                        longitudeDelta: 0.005
                    )
                )
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(trip.parkName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    mapPreview

                    addressRow

                    tripInfoCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
        }
        .background(pageBackground.ignoresSafeArea())
        .tripToolbar(
            title: "Trip Details",
            trailingTitle: "Edit",
            onTrailing: { showPlanTrip = true }
        )
        .navigationDestination(isPresented: $showPlanTrip) {
            PlanTripView(
                parkName: currentTrip.parkName,
                recommendedShadeWindow: currentTrip.recommendedShadeWindow,
                selectedDate: $selectedDate,
                viewModel: planTripViewModel,
                city: currentTrip.city,
                address: currentTrip.address,
                editingTrip: currentTrip,
                onSelectedDateChange: { newDate in
                    selectedDate = newDate
                },
                onSaveTrip: { updatedTrip in
                    selectedDate = updatedTrip.date
                    alertOption = updatedTrip.alertOption
                    shadeConditionText = updatedTrip.shadeConditionText
                    showPlanTrip = false
                }
            )
        }
    }

    private var mapPreview: some View {
        Map(position: $position) {
            Marker(
                trip.parkName,
                coordinate: tripCoordinate
            )
        }
        .frame(height: 158)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var addressRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "map")
                .font(.title3)
                .padding(.top, 2)

            Button {
                openInAppleMaps()
            } label: {
                Text(displayAddress)
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    private var tripInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Date & Time", systemImage: "calendar")
                .font(.system(size: 15, weight: .regular))

            Text(relativeTripText)
                .font(.system(size: 36, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.65)

            VStack(alignment: .leading, spacing: 2) {
                Text(longDateText)
                Text(timeRangeText)
            }
            .font(.system(size: 15, weight: .regular))

            Label(alertOption.rawValue, systemImage: "bell")
                .font(.system(size: 15, weight: .medium))

            if !trip.recommendedShadeWindow.isEmpty {
                Label("Recommended shade: \(trip.recommendedShadeWindow)", systemImage: "sun.max")
                    .font(.system(size: 15, weight: .medium))
            }

            if !shadeConditionText.isEmpty {
                Text(shadeConditionText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 38))
    }

    private var currentTrip: Trip {
        Trip(
            id: trip.id,
            parkName: trip.parkName,
            city: trip.city,
            address: trip.address,
            latitude: trip.latitude,
            longitude: trip.longitude,
            date: selectedDate,
            recommendedShadeWindow: trip.recommendedShadeWindow,
            alertOption: alertOption,
            shadeConditionText: shadeConditionText,
            savedAt: trip.savedAt
        )
    }

    private var tripCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude)
    }

    private var displayAddress: String {
        if !trip.address.isEmpty { return trip.address }
        if !trip.city.isEmpty { return trip.city }
        return trip.parkName
    }

    private var relativeTripText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: selectedDate, relativeTo: Date())
    }

    private var longDateText: String {
        selectedDate.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }

    private var timeRangeText: String {
        let endDate = selectedDate.addingTimeInterval(2 * 60 * 60)
        let start = selectedDate.formatted(date: .omitted, time: .shortened)
        let end = endDate.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    private func openInAppleMaps() {
        let coordinate = tripCoordinate
        let urlString = "https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(encodedMapQuery)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private var encodedMapQuery: String {
        let query = trip.parkName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return query ?? ""
    }

}

#Preview {
    NavigationStack {
        EditTripView(
            trip: Trip(
                parkName: "Taman Bendera Pusaka",
                city: "South Jakarta",
                address: "Taman Bendera Pusaka, Jalan Barito I, Jakarta Selatan, Indonesia",
                latitude: -6.245542,
                longitude: 106.794547,
                date: Date().addingTimeInterval(5 * 60 * 60),
                recommendedShadeWindow: "16.00 - 18.00",
                alertOption: .thirtyMinutesBefore,
                shadeConditionText: "Most of the park is shaded at this time."
            )
        )
    }
}
