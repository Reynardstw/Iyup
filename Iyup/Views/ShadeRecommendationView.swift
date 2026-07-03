import SwiftUI

struct ShadeRecommendationView: View {
    @State private var viewModel: ShadeRecommendationViewModel

        @MainActor
        init() {
            self._viewModel = State(
                initialValue: ShadeRecommendationViewModel.makePreview()
            )
        }

        @MainActor
        init(viewModel: ShadeRecommendationViewModel) {
            self._viewModel = State(initialValue: viewModel)
        }

        var body: some View {
            @Bindable var editableViewModel = viewModel

        return NavigationStack {
            List {
                Section("Interval") {
                    DatePicker(
                        "Mulai",
                        selection: $editableViewModel.startDate,
                        displayedComponents: [.hourAndMinute]
                    )

                    DatePicker(
                        "Selesai",
                        selection: $editableViewModel.endDate,
                        displayedComponents: [.hourAndMinute]
                    )

                    Button("Hitung Spot Aman") {
                        viewModel.calculateRecommendation()
                    }
                    .disabled(viewModel.isCalculating)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Ranking") {
                    ForEach(viewModel.results) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(result.spot.name)
                                    .font(.headline)

                                Spacer()

                                Text(result.safetyStatus.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                            }

                            Text("Score: \(result.shadowForecastScore, format: .number.precision(.fractionLength(2)))")
                                .font(.subheadline)

                            Text("Teduh: \(Int(result.shadeDurationMinutes.rounded())) menit")
                                .font(.subheadline)

                            Text("Kena matahari: \(Int(result.sunExposureMinutes.rounded())) menit")
                                .font(.subheadline)

                            Text(result.reason)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            timelineText(result.timeline)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Spot Teduh")
            .onAppear {
                viewModel.calculateRecommendation()
            }
        }
    }

    private func timelineText(
        _ timeline: [ShadowTimelineEntry]
    ) -> Text {
        let symbols = timeline.map { entry in
            entry.isShaded ? "1" : "0"
        }

        return Text("Timeline: \(symbols.joined(separator: ","))")
    }
}

#Preview {
    ShadeRecommendationView()
}
