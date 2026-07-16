import SwiftUI

struct TripsView: View {
    @State private var store = TripStore.shared
    @State private var selectedTrip: Trip?

    private let pageBackground = Color(.systemGroupedBackground)

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground.ignoresSafeArea()

                if store.trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationTitle("Trips")
            .navigationDestination(item: $selectedTrip) { trip in
                EditTripView(trip: trip)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()

            Image("iyuplogo")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .padding(.bottom, 4)

            Text("Let's plan your first trip")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            Text("Go to Parks to start")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var tripList: some View {
        List {
            ForEach(store.trips) { trip in
                TripCard(trip: trip) {
                    selectedTrip = trip
                }
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(
                        top: 6,
                        leading: 16,
                        bottom: 6,
                        trailing: 16
                    )
                )
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteTrips)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func deleteTrips(at offsets: IndexSet) {
        offsets.map { store.trips[$0] }.forEach{TripNotificationScheduler.cancel(for: $0)}
        store.delete(at: offsets)
    }
}

private struct TripCard: View {
    let trip: Trip
    let onTap: () -> Void

    private static let tripDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "HH.mm dd/MM/yyyy"
        return formatter
    }()

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.parkName)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(Self.tripDateFormatter.string(from: trip.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary.opacity(0.55))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
