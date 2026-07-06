import Foundation

final class PreviewIoTMQTTClient: IoTMQTTClient {
    private var timer: Timer?

    init() {
        super.init(
            configuration: .hiveMQSensorData
        )
    }

    override func connect() {
        onStateChange?(.subscribed)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            let snapshot = IoTSensorSnapshot(
                peopleCount: Int.random(in: 0...14),
                temperatureCelsius: Double.random(in: 24...35),
                humidityPercent: Double.random(in: 40...80),
                lightADC: Int.random(in: 100...3999)
            )
            self?.onSnapshot?(snapshot)
            self?.onRawMessage?("[sensor/data] {\"Orang\":\(snapshot.peopleCount),\"Suhu\":\(String(format: "%.1f", snapshot.temperatureCelsius)),\"Kelembapan\":\(String(format: "%.1f", snapshot.humidityPercent)),\"Cahaya\":\(snapshot.lightADC)}")
        }
    }

    override func disconnect() {
        timer?.invalidate()
        timer = nil
        onStateChange?(.disconnected)
    }
}
