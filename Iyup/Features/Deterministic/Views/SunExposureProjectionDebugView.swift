import SwiftUI

struct SunExposureProjectionDebugView: View {
    @State private var selectedDate = SunExposureProjectionExporter.demoDate
    @State private var entries: [SunExposureProjectionEntry] = []
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var isGenerating = false

    private let exporter = SunExposureProjectionExporter()

    var body: some View {
        NavigationStack {
            Form {
                Section("Input") {
                    DatePicker(
                        "Tanggal",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )

                    Button {
                        generateProjection()
                    } label: {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate Proyeksi 06:00–18:00")
                        }
                    }
                    .disabled(isGenerating)
                }

                if let exportedURL {
                    Section("Output CSV") {
                        Text(exportedURL.path)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }

                if !entries.isEmpty {
                    Section("Ringkasan") {
                        ForEach(summaryRows, id: \.spotID) { row in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.spotID)
                                    .font(.headline)

                                Text("Kena matahari: \(row.exposedCount) / \(row.totalCount)")
                                Text("Teduh: \(row.shadedCount) / \(row.totalCount)")
                                Text(String(format: "Rata-rata shade coverage: %.0f%%", row.averageShadeCoverage * 100))
                            }
                        }
                    }

                    Section("Preview 12 Data Pertama") {
                        ForEach(entries.prefix(12)) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(entry.hourLabel) • \(entry.spotID) • \(entry.statusLabel)")
                                    .font(.headline)

                                Text(
                                    String(
                                        format: "Alt %.1f° • Az %.1f° • Coverage %.0f%% (%d/%d)",
                                        entry.sunAltitudeDegrees,
                                        entry.sunAzimuthDegrees,
                                        entry.shadeCoverage * 100,
                                        entry.shadedSampleCount,
                                        entry.totalSampleCount
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sun Projection")
        }
    }

    private var summaryRows: [ProjectionSummaryRow] {
        let grouped = Dictionary(grouping: entries, by: \.spotID)

        return grouped.keys.sorted().compactMap { spotID in
            guard let spotEntries = grouped[spotID] else {
                return nil
            }

            let exposedCount = spotEntries.filter { $0.isExposedToSun }.count
            let shadedCount = spotEntries.count - exposedCount

            let averageShadeCoverage = spotEntries
                .map(\.shadeCoverage)
                .reduce(0.0, +) / Double(max(spotEntries.count, 1))

            return ProjectionSummaryRow(
                spotID: spotID,
                exposedCount: exposedCount,
                shadedCount: shadedCount,
                totalCount: spotEntries.count,
                averageShadeCoverage: averageShadeCoverage
            )
        }
    }

    private func generateProjection() {
        isGenerating = true
        errorMessage = nil
        exportedURL = nil

        do {
            let generatedEntries = try exporter.generate(
                date: selectedDate,
                startHour: 6,
                endHour: 18,
                stepMinutes: 15,
                includeEndTime: true
            )

            let url = try exporter.writeCSV(
                entries: generatedEntries,
                fileName: "sun_exposure_projection_06_18.csv"
            )

            entries = generatedEntries
            exportedURL = url
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}

private struct ProjectionSummaryRow: Equatable {
    let spotID: String
    let exposedCount: Int
    let shadedCount: Int
    let totalCount: Int
    let averageShadeCoverage: Double
}

#Preview {
    SunExposureProjectionDebugView()
}
