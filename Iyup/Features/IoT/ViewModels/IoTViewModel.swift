import Foundation
import Observation

@MainActor
@Observable
final class IoTViewModel {
    private(set) var state: IoTMQTTConnectionState = .disconnected
    private(set) var latestSnapshot: IoTSensorSnapshot?
    private(set) var history: [IoTSensorSnapshot] = []
    private(set) var rawMessages: [String] = []
    var errorMessage: String?

    private let client: IoTMQTTClient
    private let maxHistoryCount = 24

    init(client: IoTMQTTClient) {
        self.client = client
        bindClient()
    }

    convenience init() {
        self.init(
            client: IoTMQTTClient(
                configuration: .hiveMQSensorData
            )
        )
    }

    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let time: Date
        let value: Double
    }

    var rows: [Row] {
        guard let latestSnapshot else { return [] }

        return [
            Row(label: "Diterima", value: latestSnapshot.receivedAt.formatted(date: .omitted, time: .standard)),
            Row(label: "Jumlah Orang", value: "\(latestSnapshot.peopleCount) orang"),
            Row(label: "Suhu", value: String(format: "%.1f°C", latestSnapshot.temperatureCelsius)),
            Row(label: "Kelembapan", value: String(format: "%.1f%%", latestSnapshot.humidityPercent)),
            Row(label: "Cahaya", value: lightValueText(for: latestSnapshot)),
            Row(label: "ADC LDR", value: "\(latestSnapshot.lightADC)"),
            Row(label: "Vout LDR", value: voltageText(for: latestSnapshot)),
            Row(label: "Resistansi LDR", value: resistanceText(for: latestSnapshot))
        ]
    }

    var temperaturePoints: [ChartPoint] {
        history.map { ChartPoint(time: $0.receivedAt, value: $0.temperatureCelsius) }
    }

    var peoplePoints: [ChartPoint] {
        history.map { ChartPoint(time: $0.receivedAt, value: Double($0.peopleCount)) }
    }

    var lightPoints: [ChartPoint] {
        history.compactMap { snapshot in
            guard let lux = snapshot.estimatedLux else { return nil }
            return ChartPoint(time: snapshot.receivedAt, value: lux)
        }
    }

    var humidityPoints: [ChartPoint] {
        history.map { ChartPoint(time: $0.receivedAt, value: $0.humidityPercent) }
    }

    private func lightValueText(for snapshot: IoTSensorSnapshot) -> String {
        guard let lux = snapshot.estimatedLux else {
            return "Tidak valid / terlalu rendah"
        }

        return String(format: "%.2f lux", lux)
    }

    private func voltageText(for snapshot: IoTSensorSnapshot) -> String {
        guard let voltage = snapshot.ldrReading?.voltage else {
            return "-"
        }

        return String(format: "%.3f V", voltage)
    }

    private func resistanceText(for snapshot: IoTSensorSnapshot) -> String {
        guard let resistance = snapshot.ldrReading?.resistanceOhm else {
            return "-"
        }

        return String(format: "%.2f Ω", resistance)
    }

    func connect() {
        errorMessage = nil
        client.connect()
    }

    func disconnect() {
        client.disconnect()
    }

    func clearHistory() {
        history.removeAll()
        rawMessages.removeAll()
        latestSnapshot = nil
        errorMessage = nil
    }

    private func bindClient() {
        client.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.state = state
            }
        }

        client.onSnapshot = { [weak self] snapshot in
            Task { @MainActor in
                self?.append(snapshot)
            }
        }

        client.onRawMessage = { [weak self] message in
            Task { @MainActor in
                self?.rawMessages.insert(message, at: 0)
                if let count = self?.rawMessages.count, count > 8 {
                    self?.rawMessages.removeLast(count - 8)
                }
            }
        }

        client.onError = { [weak self] message in
            Task { @MainActor in
                self?.errorMessage = message
            }
        }
    }

    private func append(_ snapshot: IoTSensorSnapshot) {
        latestSnapshot = snapshot
        history.append(snapshot)

        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }
}
