import SwiftUI

struct TripsView: View {
    @State private var store = TripStore.shared

    private let pageBackground = Color(red: 0.92, green: 0.94, blue: 1.00)

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
        }
    }

    // MARK: Empty  state (sesuai desain)

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()

            Image("iyuplogo")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
                .padding(.bottom, 4)

            Text("Let's plan your first trip")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            Text("Go to Parks to start")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: List

    private var tripList: some View {
        List {
            ForEach(store.trips) { trip in
                TripCard(trip: trip)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteTrips)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func deleteTrips(at offsets: IndexSet) {
        offsets.map { store.trips[$0] }.forEach(TripNotificationScheduler.cancel)
        store.delete(at: offsets)
    }
}

// MARK: - Trip card

private struct TripCard: View {
    let trip: Trip

    var body: some View {
        // Pindahkan NavigationLink untuk membungkus seluruh konten card
        NavigationLink {
            EditTripView(trip: trip)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.parkName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(trip.city.isEmpty ? trip.address : trip.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Hapus Image chevron manual di sini,
                // karena List sudah otomatis memberikannya
                Spacer(minLength: 8)
            }
            // Pindahkan modifier padding dan background ke dalam label NavigationLink
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        // Hapus style bawaan NavigationLink agar teks tidak menjadi biru
        .buttonStyle(.plain)
    }
}
