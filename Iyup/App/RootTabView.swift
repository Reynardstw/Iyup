import SwiftUI

private enum RootTab: Hashable {
    case parks
    case trips
    case search
}

struct RootTabView: View {
    @State private var selectedTab: RootTab = .parks

    // Ungu brand (sama dengan accent app).
    private let brandPurple = Color(red: 153/255, green: 69/255, blue: 236/255)

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Parks", systemImage: "tree", value: RootTab.parks) {
                ShadeMapView(
                    onTripSavedNavigateToTrips: {
                        selectedTab = .trips
                    }
                )
            }

            Tab("Trips", systemImage: "mappin.and.ellipse", value: RootTab.trips) {
                TripsView()
            }

            // Tombol search terpisah (floating) — muncul karena role: .search.
            Tab(value: RootTab.search, role: .search) {
                SearchPlaceholderView()
            }
        }
        .tint(brandPurple)   // warna tab terpilih jadi ungu
    }
}

/// Placeholder isi tab Search. Ganti dengan layar search asli nanti.
private struct SearchPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Search",
                systemImage: "magnifyingglass",
                description: Text("Cari taman di sini.")
            )
            .navigationTitle("Search")
        }
    }
}

#Preview {
    RootTabView()
}
