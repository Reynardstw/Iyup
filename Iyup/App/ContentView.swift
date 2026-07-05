import SwiftUI

struct ContentView: View {
    @State private var viewModel: MLShadeRecommendationViewModel

    @MainActor
    init() {
        _viewModel = State(
            initialValue: AppComposition.makeScoreViewModel()
        )
    }

    var body: some View {
        TabView {
            Tab("Deterministik", systemImage: "cloud.sun") {
                DeterministicShadowView(viewModel: viewModel)
            }

            Tab("Ranking ML", systemImage: "sparkles") {
                MLShadeRankingView(viewModel: viewModel)
            }

            Tab("Shade Map", systemImage: "map") {
                ShadeMapView()
            }
        }
        .task {
            let debugRunID = "AUTO-" + String(UUID().uuidString.prefix(8))
            await viewModel.calculate(debugRunID: debugRunID)
        }
    }
}

#Preview {
    ContentView()
}
