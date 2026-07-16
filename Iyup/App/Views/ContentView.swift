import SwiftUI

private enum RootTab: Hashable {
    case parks
    case trips
    case search
}

struct ContentView: View {
    @State private var selectedTab: RootTab = .parks

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

            Tab(value: RootTab.search, role: .search) {
                SearchPlaceholderView()
            }
        }
    }
}

private struct SearchPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Search",
                systemImage: "magnifyingglass",
                description: Text("Search your park here.")
            )
            .navigationTitle("Search")
        }
    }
}

#Preview {
    ContentView()
}
