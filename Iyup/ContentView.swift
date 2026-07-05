import SwiftUI

struct ContentView: View {
    @State private var viewModel: MLShadeRecommendationViewModel

    @MainActor
    init() {
        _viewModel = State(
            initialValue: MLShadeRecommendationDemoFactory.makeViewModel()
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

struct ShadeIntervalSection: View {
    @Bindable var viewModel: MLShadeRecommendationViewModel

    var body: some View {
        Section("Interval") {
            DatePicker(
                "Mulai",
                selection: $viewModel.startDate,
                displayedComponents: [.hourAndMinute]
            )

            DatePicker(
                "Selesai",
                selection: $viewModel.endDate,
                displayedComponents: [.hourAndMinute]
            )

            Button("Hitung") {
                let debugRunID = "BTN-" + String(UUID().uuidString.prefix(8))
                Task {
                    await viewModel.calculate(debugRunID: debugRunID)
                }
            }
            .disabled(viewModel.isCalculating)
        }
    }
}

#Preview {
    ContentView()
}
