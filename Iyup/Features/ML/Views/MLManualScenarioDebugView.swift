import SwiftUI
import CoreML

struct MLManualScenarioDebugView: View {
    @State private var resultRows: [ManualMLScenarioResult] = []
    @State private var summaryText = "Belum jalan. Tekan Run Scenario."
    @State private var errorMessage: String?
    @State private var isRunning = false
    @State private var useAppFallback = false

    var body: some View {
        NavigationStack {
            List {
                Section("Tujuan") {
                    Text("View ini bypass ViewModel, bypass scoring, dan bypass raycast. Dia langsung load .mlmodel dari bundle lalu input manual scenario projection 70%. Kalau hasil di sini rendah tapi Ranking ML tinggi, berarti masalahnya ada di pipeline app/scoring/input runtime. Kalau di sini juga tinggi, berarti .mlmodel yang kebaca memang model lama/salah.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Pakai fallback legacy app lama", isOn: $useAppFallback)
                    Text(useAppFallback ? "LEGACY: occupancy fallback teduh 0.45, kena 0.25" : "V3: occupancy fallback teduh 0.18, kena 0.12")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await runScenario() }
                    } label: {
                        Label("Run Manual ML Scenario", systemImage: "play.circle")
                    }
                    .disabled(isRunning)
                }

                Section("Summary") {
                    Text(summaryText)
                        .font(.footnote)
                        .monospacedDigit()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Rows") {
                    ForEach(resultRows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(row.timeText)  \(row.benchID)")
                                    .font(.headline)
                                Spacer()
                                Text(row.isFutureShaded ? "TEDUH" : "KENA")
                                    .font(.caption.bold())
                                    .foregroundStyle(row.isFutureShaded ? .green : .orange)
                            }

                            HStack(spacing: 12) {
                                Text("shade \(row.shadeCoverage, format: .number.precision(.fractionLength(2)))")
                                Text("alt \(row.sunAltitude, format: .number.precision(.fractionLength(1)))°")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                MetricPill(title: "Short Occ", value: row.shortOccupancy)
                                MetricPill(title: "Long Occ", value: row.longOccupancy)
                            }

                            HStack(spacing: 12) {
                                Text("Lux S/L: \(Int(row.shortLux.rounded())) / \(Int(row.longLux.rounded()))")
                                Text("Temp S/L: \(row.shortTemp, format: .number.precision(.fractionLength(1))) / \(row.longTemp, format: .number.precision(.fractionLength(1)))")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("ML Input Debug")
            .overlay {
                if isRunning {
                    ProgressView()
                }
            }
        }
    }

    @MainActor
    private func runScenario() async {
        isRunning = true
        errorMessage = nil
        defer { isRunning = false }

        do {
            let runner = ManualMLScenarioRunner(useAppFallback: useAppFallback)
            let rows = try runner.run()
            resultRows = rows

            let shortMean = rows.map(\.shortOccupancy).average
            let longMean = rows.map(\.longOccupancy).average
            let shortMax = rows.map(\.shortOccupancy).max() ?? 0
            let longMax = rows.map(\.longOccupancy).max() ?? 0
            let shortOver60 = rows.filter { $0.shortOccupancy > 0.60 }.count
            let longOver60 = rows.filter { $0.longOccupancy > 0.60 }.count

            summaryText = """
            rows: \(rows.count)
            short occ mean: \(shortMean.asPercent), max: \(shortMax.asPercent), >60%: \(shortOver60)
            long  occ mean: \(longMean.asPercent), max: \(longMax.asPercent), >60%: \(longOver60)
            expected sehat: max sekitar 50%, >60% harus 0 atau sangat sedikit.
            """

            print("🧪 [MLManualDebug] \(summaryText)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [MLManualDebug] Failed: \(error)")
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: Double

    var body: some View {
        Text("\(title): \(value.asPercent)")
            .font(.caption.monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(value > 0.60 ? Color.red.opacity(0.18) : Color.green.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct ManualMLScenarioResult: Identifiable {
    let id = UUID()
    let timeText: String
    let benchID: String
    let isFutureShaded: Bool
    let shadeCoverage: Double
    let sunAltitude: Double
    let shortOccupancy: Double
    let longOccupancy: Double
    let shortLux: Double
    let longLux: Double
    let shortTemp: Double
    let longTemp: Double
}

private final class ManualMLScenarioRunner {
    private enum ModelKey: String, CaseIterable {
        case shortLux = "short_lux"
        case shortTemp = "short_temp"
        case shortOccupancy = "short_occupancy"
        case longLux = "long_lux"
        case longTemp = "long_temp"
        case longOccupancy = "long_occupancy"

        var modelName: String {
            switch self {
            case .shortLux: return "IyupShortLuxV2"
            case .shortTemp: return "IyupShortTempV2"
            case .shortOccupancy: return "IyupShortOccupancyV2"
            case .longLux: return "IyupLongLuxV2"
            case .longTemp: return "IyupLongTempV2"
            case .longOccupancy: return "IyupLongOccupancyV2"
            }
        }

        var manifestName: String {
            "iyup_features_\(rawValue)_v2"
        }

        var outputName: String {
            switch self {
            case .shortLux, .longLux: return "predicted_lux"
            case .shortTemp, .longTemp: return "predicted_temp"
            case .shortOccupancy, .longOccupancy: return "predicted_occupancy"
            }
        }
    }

    private struct ModelManifest: Decodable {
        let features_ordered: [String]
        let spot_mapping: [String: Int]
    }

    private struct LoadedModel {
        let model: MLModel
        let features: [String]
        let outputName: String
        let sourcePath: String
    }

    private struct ScenarioPoint {
        let timeText: String
        let benchID: String
        let spotID: String
        let spotNumber: Int
        let futureShaded: Bool
        let shadeCoverage: Double
        let sunAltitude: Double
    }

    private let useAppFallback: Bool
    private let calendar: Calendar

    init(useAppFallback: Bool) {
        self.useAppFallback = useAppFallback
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        self.calendar = cal
    }

    func run() throws -> [ManualMLScenarioResult] {
        let models = try Dictionary(
            uniqueKeysWithValues: ModelKey.allCases.map { key in
                (key, try loadModel(for: key))
            }
        )

        for key in ModelKey.allCases {
            if let model = models[key] {
                print("📦 [MLManualDebug] loaded \(key.modelName) from: \(model.sourcePath)")
            }
        }

        let referenceDate = date(hour: 6, minute: 45)
        let scenarios = makeScenarioPoints()

        return try scenarios.map { scenario in
            let current = currentPoint(for: scenario.benchID)
            let sampleDate = date(from: scenario.timeText)
            let shortLux = try predict(
                .shortLux,
                models: models,
                features: makeFeatures(for: .shortLux, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )
            let longLux = try predict(
                .longLux,
                models: models,
                features: makeFeatures(for: .longLux, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )
            let shortTemp = try predict(
                .shortTemp,
                models: models,
                features: makeFeatures(for: .shortTemp, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )
            let longTemp = try predict(
                .longTemp,
                models: models,
                features: makeFeatures(for: .longTemp, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )
            let shortOcc = try predict(
                .shortOccupancy,
                models: models,
                features: makeFeatures(for: .shortOccupancy, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )
            let longOcc = try predict(
                .longOccupancy,
                models: models,
                features: makeFeatures(for: .longOccupancy, scenario: scenario, current: current, sampleDate: sampleDate, referenceDate: referenceDate)
            )

            print("🧪 [MLManualDebug] \(scenario.timeText) \(scenario.benchID) shaded=\(scenario.futureShaded ? 1 : 0) shortOcc=\(shortOcc) longOcc=\(longOcc)")

            return ManualMLScenarioResult(
                timeText: scenario.timeText,
                benchID: scenario.benchID,
                isFutureShaded: scenario.futureShaded,
                shadeCoverage: scenario.shadeCoverage,
                sunAltitude: scenario.sunAltitude,
                shortOccupancy: shortOcc.clamped01,
                longOccupancy: longOcc.clamped01,
                shortLux: shortLux,
                longLux: longLux,
                shortTemp: shortTemp,
                longTemp: longTemp
            )
        }
    }

    private func makeFeatures(
        for key: ModelKey,
        scenario: ScenarioPoint,
        current: ScenarioPoint,
        sampleDate: Date,
        referenceDate: Date
    ) -> [String: Double] {
        let components = calendar.dateComponents([.hour, .minute, .weekday], from: sampleDate)
        let hour = Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        let dayOfWeek = Double(((components.weekday ?? 1) + 5) % 7)
        let horizonMinutes = max(sampleDate.timeIntervalSince(referenceDate) / 60.0, 0.0)
        let leadDays = max(1.0, min(7.0, ceil(sampleDate.timeIntervalSince(referenceDate) / 86_400.0)))

        let currentFallbackOccupancy = useAppFallback
            ? (current.futureShaded ? 0.45 : 0.25)
            : (current.futureShaded ? 0.18 : 0.12)

        let currentLux = fallbackLuxValue(
            isShaded: current.futureShaded,
            sunAltitudeDegrees: current.sunAltitude
        )
        let currentTemp = fallbackTemperatureValue(
            isShaded: current.futureShaded,
            sunAltitudeDegrees: current.sunAltitude
        )

        let modelShadowStatus: Double
        let modelSunAltitude: Double

        switch key {
        case .longLux, .longTemp, .longOccupancy:
            modelShadowStatus = scenario.futureShaded ? 1.0 : 0.0
            modelSunAltitude = scenario.sunAltitude
        case .shortLux, .shortTemp, .shortOccupancy:
            modelShadowStatus = current.futureShaded ? 1.0 : 0.0
            modelSunAltitude = current.sunAltitude
        }

        return [
            "spot_num": Double(scenario.spotNumber),
            "hour": hour,
            "day_of_week": dayOfWeek,
            "is_weekend": dayOfWeek >= 5 ? 1.0 : 0.0,
            "is_holiday": 0.0,
            "horizon": horizonMinutes,
            "lead_days": leadDays,
            "shadow_status": modelShadowStatus,
            "shadow_status_future": scenario.futureShaded ? 1.0 : 0.0,
            "sun_altitude": modelSunAltitude,
            "sun_altitude_future": scenario.sunAltitude,
            "cloud_cover": 0.30,
            "cloud_forecast": 0.30,
            "cloud_forecast_future": 0.30,
            "lux": currentLux,
            "lux_lag_15m": currentLux,
            "lux_lag_30m": currentLux,
            "lux_lag_60m": currentLux,
            "lux_rollmean_30m": currentLux,
            "lux_trend": 0.0,
            "temp": currentTemp,
            "temp_lag_15m": currentTemp,
            "temp_lag_30m": currentTemp,
            "temp_lag_60m": currentTemp,
            "temp_rollmean_30m": currentTemp,
            "temp_trend": 0.0,
            "occupancy": currentFallbackOccupancy,
            "occupancy_lag_15m": currentFallbackOccupancy,
            "occupancy_lag_30m": currentFallbackOccupancy,
            "occupancy_lag_60m": currentFallbackOccupancy,
            "occupancy_rollmean_30m": currentFallbackOccupancy,
            "occupancy_trend": 0.0
        ]
    }

    private func fallbackLuxValue(isShaded: Bool, sunAltitudeDegrees: Double) -> Double {
        let sunStrength = max(0.0, sin(sunAltitudeDegrees * .pi / 180.0))
        let openLux = 105_000.0 * pow(sunStrength, 1.15) * 0.78
        let shadedLux = max(600.0, openLux * 0.12 + 450.0)
        return max(0.0, isShaded ? shadedLux : openLux)
    }

    private func fallbackTemperatureValue(isShaded: Bool, sunAltitudeDegrees: Double) -> Double {
        let sunStrength = max(0.0, sin(sunAltitudeDegrees * .pi / 180.0))
        let base = 29.0 + 2.5 * sunStrength
        return isShaded ? max(25.0, base - 1.2) : min(36.0, base + 0.6)
    }

    private func predict(
        _ key: ModelKey,
        models: [ModelKey: LoadedModel],
        features: [String: Double]
    ) throws -> Double {
        guard let loaded = models[key] else {
            throw NSError(domain: "MLManualDebug", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model missing: \(key.modelName)"])
        }

        var dictionary: [String: MLFeatureValue] = [:]
        for feature in loaded.features {
            guard let value = features[feature], value.isFinite else {
                throw NSError(domain: "MLManualDebug", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing feature \(feature) for \(key.modelName)"])
            }
            dictionary[feature] = MLFeatureValue(double: value)
        }

        if key == .shortOccupancy || key == .longOccupancy {
            print("🧪 [MLManualDebug] INPUT for \(key.modelName)")
            for feature in loaded.features {
                let value = dictionary[feature]?.doubleValue ?? -999.0
                print("🧪 [MLManualDebug] \(key.modelName).input[\(feature)] = \(value)")
            }
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: dictionary)
        let output = try loaded.model.prediction(from: provider)

        guard let value = output.featureValue(for: loaded.outputName) else {
            let names = Array(output.featureNames).sorted().joined(separator: ", ")
            throw NSError(domain: "MLManualDebug", code: 3, userInfo: [NSLocalizedDescriptionKey: "Output \(loaded.outputName) missing for \(key.modelName). Available: \(names)"])
        }

        return value.doubleValue
    }

    private func loadModel(for key: ModelKey) throws -> LoadedModel {
        let manifest = try loadManifest(for: key)
        let modelResult = try loadCoreMLModel(named: key.modelName)
        return LoadedModel(
            model: modelResult.model,
            features: manifest.features_ordered,
            outputName: key.outputName,
            sourcePath: modelResult.path
        )
    }

    private func loadManifest(for key: ModelKey) throws -> ModelManifest {
        guard let url = resourceURL(
            name: key.manifestName,
            extensionName: "json",
            subdirectories: [nil, "MLModels/Json", "Features/ML/Resources/Json"]
        ) else {
            throw NSError(domain: "MLManualDebug", code: 4, userInfo: [NSLocalizedDescriptionKey: "Manifest not found: \(key.manifestName).json"])
        }

        return try JSONDecoder().decode(ModelManifest.self, from: Data(contentsOf: url))
    }

    private func loadCoreMLModel(named name: String) throws -> (model: MLModel, path: String) {
        if let compiledURL = resourceURL(
            name: name,
            extensionName: "mlmodelc",
            subdirectories: [nil, "MLModels/Models", "Features/ML/Resources/Models"]
        ) {
            return (try MLModel(contentsOf: compiledURL), compiledURL.path)
        }

        if let modelURL = resourceURL(
            name: name,
            extensionName: "mlmodel",
            subdirectories: [nil, "MLModels/Models", "Features/ML/Resources/Models"]
        ) {
            let compiledURL = try MLModel.compileModel(at: modelURL)
            return (try MLModel(contentsOf: compiledURL), modelURL.path)
        }

        throw NSError(domain: "MLManualDebug", code: 5, userInfo: [NSLocalizedDescriptionKey: "Core ML model not found: \(name)"])
    }

    private func resourceURL(name: String, extensionName: String, subdirectories: [String?]) -> URL? {
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: extensionName, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }

    private func date(from timeText: String) -> Date {
        let parts = timeText.split(separator: ":").compactMap { Int($0) }
        return date(hour: parts.first ?? 0, minute: parts.dropFirst().first ?? 0)
    }

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2026,
                month: 3,
                day: 7,
                hour: hour,
                minute: minute
            )
        ) ?? Date()
    }

    private func currentPoint(for benchID: String) -> ScenarioPoint {
        scenarioPoint(time: "06:45", bench: benchID)
    }

    private func makeScenarioPoints() -> [ScenarioPoint] {
        let times = ["07:00", "08:00", "10:00", "12:00", "14:00", "16:00", "17:00"]
        let benches = ["Bench1", "Bench2", "Bench3", "Bench4", "Bench5"]
        return times.flatMap { time in
            benches.map { bench in
                scenarioPoint(time: time, bench: bench)
            }
        }
    }

    private func scenarioPoint(time: String, bench: String) -> ScenarioPoint {
        let spotInfo: (String, Int)
        switch bench {
        case "Bench1": spotInfo = ("Spot_A", 0)
        case "Bench2": spotInfo = ("Spot_B", 1)
        case "Bench3": spotInfo = ("Spot_C", 2)
        case "Bench4": spotInfo = ("Spot_D", 3)
        case "Bench5": spotInfo = ("Spot_E", 4)
        default: spotInfo = (bench, 0)
        }

        let sunAltitude: Double
        switch time {
        case "06:45": sunAltitude = 10.7528
        case "07:00": sunAltitude = 14.4711
        case "08:00": sunAltitude = 29.3585
        case "10:00": sunAltitude = 59.1725
        case "12:00": sunAltitude = 88.6334
        case "14:00": sunAltitude = 61.0972
        case "16:00": sunAltitude = 31.2757
        case "17:00": sunAltitude = 16.3811
        default: sunAltitude = 0.0
        }

        let coverage = shadeCoverage(time: time, bench: bench)
        return ScenarioPoint(
            timeText: time,
            benchID: bench,
            spotID: spotInfo.0,
            spotNumber: spotInfo.1,
            futureShaded: coverage >= 0.70,
            shadeCoverage: coverage,
            sunAltitude: sunAltitude
        )
    }

    private func shadeCoverage(time: String, bench: String) -> Double {
        switch (time, bench) {
        case ("06:45", "Bench2"): return 0.6667
        case ("06:45", "Bench4"): return 1.0
        case ("06:45", "Bench5"): return 0.2222
        case ("07:00", "Bench2"), ("07:00", "Bench4"):
            return 1.0
        case ("08:00", "Bench2"), ("08:00", "Bench4"):
            return 1.0
        case ("10:00", "Bench2"), ("10:00", "Bench4"):
            return 1.0
        case ("12:00", "Bench2"):
            return 0.2222
        case ("12:00", "Bench4"):
            return 0.3333
        case ("14:00", "Bench5"), ("16:00", "Bench5"):
            return 1.0
        default:
            return 0.0
        }
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

private extension Double {
    var clamped01: Double {
        min(max(self, 0.0), 1.0)
    }

    var asPercent: String {
        "\(Int((self * 100).rounded()))%"
    }
}

#Preview {
    MLManualScenarioDebugView()
}
