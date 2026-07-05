import SwiftUI


struct DeterministicShadowView: View {
    @Bindable var viewModel: MLShadeRecommendationViewModel

    var body: some View {
        NavigationStack {
            List {
                ShadeIntervalSection(viewModel: viewModel)

                if let errorMessage = viewModel.errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if viewModel.shadowResults.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Belum ada hasil",
                            systemImage: "cloud.sun",
                            description: Text("Tekan Hitung untuk menjalankan kalkulasi bayangan.")
                        )
                    }
                } else {
                    Section("Rincian Shadowmap") {
                        ForEach(viewModel.shadowResults) { result in
                            ShadowResultRow(result: result)
                        }
                    }
                }
            }
            .navigationTitle("Shadow Deterministik")
            .overlay {
                if viewModel.isCalculating {
                    ProgressView()
                }
            }
        }
    }
}


private struct ShadowResultRow: View {
    let result: ShadowIntervalResult

    var body: some View {
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

            Text("Shadow score: \(result.shadowForecastScore, format: .number.precision(.fractionLength(2)))")
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

    private func timelineText(_ timeline: [ShadowTimelineEntry]) -> Text {
        let symbols = timeline.map { $0.isShaded ? "1" : "0" }
        return Text("Timeline: \(symbols.joined(separator: ","))")
    }
}

#Preview {
    DeterministicShadowView(
        viewModel: AppComposition.makeMockScoreViewModel()
    )
}
