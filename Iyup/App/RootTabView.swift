import SwiftUI

private enum RootTab: Hashable {
    case parks
    case trips
}

struct RootTabView: View {
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
        }
    }
}

#Preview {
    RootTabView()
}
