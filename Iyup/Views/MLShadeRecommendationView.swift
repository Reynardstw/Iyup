//import SwiftUI
//
///// ML-enhanced view.
/////
///// This is intentionally separate from ShadeRecommendationView to avoid merging
///// the shadow-only UI and the ML UI in one file.
//struct MLShadeRecommendationView: View {
//    @State private var viewModel: MLShadeRecommendationViewModel
//
//    @MainActor
//    init(viewModel: MLShadeRecommendationViewModel) {
//        self._viewModel = State(initialValue: viewModel)
//    }
//
//    var body: some View {
//        @Bindable var editableViewModel = viewModel
//
//        return NavigationStack {
//            List {
//                Section("Interval") {
//                    DatePicker(
//                        "Mulai",
//                        selection: $editableViewModel.startDate,
//                        displayedComponents: [.hourAndMinute]
//                    )
//
//                    DatePicker(
//                        "Selesai",
//                        selection: $editableViewModel.endDate,
//                        displayedComponents: [.hourAndMinute]
//                    )
//
//                    Button("Hitung Ranking ML") {
//                        let debugRunID = "BTN-" + String(UUID().uuidString.prefix(8))
//
//                        print("")
//                        print("🟢 [MLShade][\(debugRunID)] BUTTON PRESSED: Hitung Ranking ML")
//                        print("🟢 [MLShade][\(debugRunID)] View triggers ranking calculation")
//
//                        Task {
//                            print("🧭 [MLShade][\(debugRunID)] Calling ViewModel.calculate(debugRunID:)")
//                            await viewModel.calculate(debugRunID: debugRunID)
//                            print("✅ [MLShade][\(debugRunID)] ViewModel calculate finished")
//                        }
//                    }
//                    .disabled(viewModel.isCalculating)
//                }
//
//                if let errorMessage = viewModel.errorMessage {
//                    Section("Error") {
//                        Text(errorMessage)
//                            .foregroundStyle(.red)
//                    }
//                }
//
//                if !viewModel.scoredResults.isEmpty {
//                    Section("Ranking Final") {
//                        ForEach(Array(viewModel.scoredResults.enumerated()), id: \.element.id) { index, scored in
//                            scoredRow(rank: index + 1, scored: scored)
//                        }
//                    }
//                }
//
//                Section("Rincian Shadowmap") {
//                    ForEach(viewModel.shadowResults) { result in
//                        shadowRow(result)
//                    }
//                }
//            }
//            .navigationTitle("Spot Teduh ML")
//            .overlay {
//                if viewModel.isCalculating {
//                    ProgressView()
//                }
//            }
//            .task {
//                let debugRunID = "AUTO-" + String(UUID().uuidString.prefix(8))
//                print("🔄 [MLShade][\(debugRunID)] Auto calculate from .task started")
//                await viewModel.calculate(debugRunID: debugRunID)
//                print("✅ [MLShade][\(debugRunID)] Auto calculate from .task finished")
//            }
//        }
//    }
//
//    @ViewBuilder
//    private func scoredRow(rank: Int, scored: MLShadeScoredSpotResult) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text("#\(rank)")
//                    .font(.title3.bold())
//                    .foregroundStyle(.secondary)
//
//                Text(scored.spot.name)
//                    .font(.headline)
//
//                Spacer()
//
//                Text(scored.shadowResult.safetyStatus.rawValue)
//                    .font(.caption)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(.thinMaterial)
//                    .clipShape(Capsule())
//            }
//
//            ProgressView(value: scored.finalScore) {
//                Text("Final score: \(scored.finalScore, format: .number.precision(.fractionLength(2)))")
//                    .font(.caption)
//            }
//            .tint(tintColor(for: scored.finalScore))
//
//            HStack(spacing: 12) {
//                Label(
//                    "\(Int(scored.shadowResult.shadeDurationMinutes.rounded())) mnt teduh",
//                    systemImage: "cloud.sun"
//                )
//
//                Label(scored.occupancyLabel, systemImage: "person.3")
//
//                Label(
//                    String(format: "%.1f°C", scored.meanPredictedTemperature),
//                    systemImage: "thermometer.medium"
//                )
//            }
//            .font(.caption)
//            .foregroundStyle(.secondary)
//
//            Text(scored.shadowResult.reason)
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//
//            ForEach(scored.environmentReasons, id: \.self) { reason in
//                Text("• \(reason)")
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding(.vertical, 6)
//    }
//
//    @ViewBuilder
//    private func shadowRow(_ result: ShadowIntervalResult) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                Text(result.spot.name)
//                    .font(.headline)
//
//                Spacer()
//
//                Text(result.safetyStatus.rawValue)
//                    .font(.caption)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(.thinMaterial)
//                    .clipShape(Capsule())
//            }
//
//            Text("Shadow score: \(result.shadowForecastScore, format: .number.precision(.fractionLength(2)))")
//                .font(.subheadline)
//
//            Text("Teduh: \(Int(result.shadeDurationMinutes.rounded())) menit")
//                .font(.subheadline)
//
//            Text("Kena matahari: \(Int(result.sunExposureMinutes.rounded())) menit")
//                .font(.subheadline)
//
//            Text(result.reason)
//                .font(.footnote)
//                .foregroundStyle(.secondary)
//
//            timelineText(result.timeline)
//                .font(.caption.monospaced())
//                .foregroundStyle(.secondary)
//        }
//        .padding(.vertical, 6)
//    }
//
//    private func tintColor(for score: Double) -> Color {
//        switch score {
//        case 0.8...:
//            return .green
//        case 0.5..<0.8:
//            return .orange
//        default:
//            return .red
//        }
//    }
//
//    private func timelineText(_ timeline: [ShadowTimelineEntry]) -> Text {
//        let symbols = timeline.map { $0.isShaded ? "1" : "0" }
//        return Text("Timeline: \(symbols.joined(separator: ","))")
//    }
//}
//
//#Preview {
//    MLShadeRecommendationView(
//        viewModel: MLShadeRecommendationDemoFactory.makeMockViewModel()
//    )
//}
