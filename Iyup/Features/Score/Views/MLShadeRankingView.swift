import SwiftUI


struct MLShadeRankingView: View {
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

                if viewModel.scoredResults.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "Belum ada ranking",
                            systemImage: "sparkles",
                            description: Text("Tekan Hitung untuk menjalankan forecast dan scoring ML.")
                        )
                    }
                } else {
                    Section("Ranking Final") {
                        ForEach(
                            Array(viewModel.scoredResults.enumerated()),
                            id: \.element.id
                        ) { index, scored in
                            ScoredResultRow(rank: index + 1, scored: scored)
                        }
                    }
                }
            }
            .navigationTitle("Spot Teduh ML")
            .overlay {
                if viewModel.isCalculating {
                    ProgressView()
                }
            }
        }
    }
}


private struct ScoredResultRow: View {
    let rank: Int
    let scored: MLShadeScoredSpotResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(rank)")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)

                Text(scored.spot.name)
                    .font(.headline)

                Spacer()

                Text(scored.shadowResult.safetyStatus.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            ProgressView(value: scored.finalScore) {
                Text("Final score: \(scored.finalScore, format: .number.precision(.fractionLength(2)))")
                    .font(.caption)
            }
            .tint(tintColor(for: scored.finalScore))

            HStack(spacing: 12) {
                Label(
                    "\(Int(scored.shadowResult.shadeDurationMinutes.rounded())) mnt teduh",
                    systemImage: "cloud.sun"
                )

                Label(scored.occupancyLabel, systemImage: "person.3")

                Label(
                    String(format: "%.1f°C", scored.meanPredictedTemperature),
                    systemImage: "thermometer.medium"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(scored.shadowResult.reason)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(scored.environmentReasons, id: \.self) { reason in
                Text("• \(reason)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func tintColor(for score: Double) -> Color {
        switch score {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    MLShadeRankingView(
        viewModel: AppComposition.makeMockScoreViewModel()
    )
}
