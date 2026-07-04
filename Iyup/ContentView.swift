import SwiftUI

/// Composition root.
///
/// ContentView memegang SATU ViewModel bersama dan membaginya ke dua view
/// terpisah lewat TabView. ViewModel harus satu karena pipeline-nya
/// berurutan: hasil shadow deterministik adalah input untuk scoring ML —
/// satu kali "Hitung" mengisi kedua tab.
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
        }
        // Auto-calculate sekali saat root muncul — bukan di masing-masing
        // view, supaya pindah tab tidak memicu kalkulasi ulang.
        .task {
            let debugRunID = "AUTO-" + String(UUID().uuidString.prefix(8))
            await viewModel.calculate(debugRunID: debugRunID)
        }
    }
}

// MARK: - Shared: kontrol interval + tombol hitung

/// Dipakai oleh kedua view. Binding-nya menunjuk ke ViewModel bersama,
/// jadi mengubah jam di satu tab otomatis tersinkron di tab lain.
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
