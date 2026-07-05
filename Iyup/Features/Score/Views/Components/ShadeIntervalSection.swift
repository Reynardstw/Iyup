import SwiftUI

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
