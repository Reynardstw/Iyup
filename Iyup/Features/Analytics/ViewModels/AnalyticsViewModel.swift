import Foundation
import Observation

@MainActor
@Observable
final class AnalyticsViewModel {
    private(set) var weatherSnapshots: [AnalyticsWeatherNoonSnapshot] = []
    private(set) var isWeatherLoading = false
    private(set) var weatherLastFetchedAt: Date?
    var weatherErrorMessage: String?

    private(set) var iotState: IoTMQTTConnectionState = .disconnected
    private(set) var latestIoTSnapshot: IoTSensorSnapshot?
    private(set) var iotHistory: [IoTSensorSnapshot] = []
    private(set) var rawIoTMessages: [String] = []
    var iotErrorMessage: String?

    let latitude: Double
    let longitude: Double

    private let weatherService: any AnalyticsWeatherProviding
    private let iotClient: IoTMQTTClient
    private let maxIoTHistoryCount = 48

    init(
        weatherService: any AnalyticsWeatherProviding,
        iotClient: IoTMQTTClient,
        latitude: Double,
        longitude: Double
    ) {
        self.weatherService = weatherService
        self.iotClient = iotClient
        self.latitude = latitude
        self.longitude = longitude
        bindIoTClient()
    }

    convenience init() {
        self.init(
            weatherService: WeatherKitAnalyticsWeatherService(),
            iotClient: IoTMQTTClient(configuration: .hiveMQSensorData),
            latitude: -6.2000,
            longitude: 106.8167
        )
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let value: Double
    }

    var weatherTemperaturePoints: [ChartPoint] {
        weatherSnapshots.map {
            ChartPoint(date: $0.date, label: dayLabel($0.date), value: $0.temperatureCelsius)
        }
    }

    var weatherHumidityPoints: [ChartPoint] {
        weatherSnapshots.map {
            ChartPoint(date: $0.date, label: dayLabel($0.date), value: $0.humidityPercent)
        }
    }

    var weatherCloudCoverPoints: [ChartPoint] {
        weatherSnapshots.map {
            ChartPoint(date: $0.date, label: dayLabel($0.date), value: $0.cloudCoverPercent)
        }
    }

    var weatherRainPoints: [ChartPoint] {
        weatherSnapshots.map {
            ChartPoint(date: $0.date, label: dayLabel($0.date), value: $0.precipitationMillimeters)
        }
    }

    var iotTemperaturePoints: [ChartPoint] {
        iotHistory.map {
            ChartPoint(date: $0.receivedAt, label: timeLabel($0.receivedAt), value: $0.temperatureCelsius)
        }
    }

    var iotPeoplePoints: [ChartPoint] {
        iotHistory.map {
            ChartPoint(date: $0.receivedAt, label: timeLabel($0.receivedAt), value: Double($0.peopleCount))
        }
    }

    var iotHumidityPoints: [ChartPoint] {
        iotHistory.map {
            ChartPoint(date: $0.receivedAt, label: timeLabel($0.receivedAt), value: $0.humidityPercent)
        }
    }

    var iotLightPoints: [ChartPoint] {
        iotHistory.compactMap { snapshot in
            guard let lux = snapshot.estimatedLux else { return nil }
            return ChartPoint(date: snapshot.receivedAt, label: timeLabel(snapshot.receivedAt), value: lux)
        }
    }

    var weatherSummaryText: String {
        guard !weatherSnapshots.isEmpty else {
            return "Belum ada data weather analytics. Tekan tombol fetch untuk mengambil 7 titik data jam 12."
        }

        let averageTemperature = weatherSnapshots.map(\.temperatureCelsius).reduce(0, +) / Double(weatherSnapshots.count)
        let averageHumidity = weatherSnapshots.map(\.humidityPercent).reduce(0, +) / Double(weatherSnapshots.count)

        return String(
            format: "Rata-rata jam 12: %.1f°C, kelembapan %.0f%% dari %d titik data.",
            averageTemperature,
            averageHumidity,
            weatherSnapshots.count
        )
    }

    var iotSummaryText: String {
        guard !iotHistory.isEmpty else {
            return "Belum ada data IoT. Tekan Connect untuk mulai menerima payload ESP32."
        }

        let averageTemperature = iotHistory.map(\.temperatureCelsius).reduce(0, +) / Double(iotHistory.count)
        let latestPeople = latestIoTSnapshot?.peopleCount ?? 0

        return String(
            format: "Data IoT masuk: %d sampel. Suhu rata-rata %.1f°C. Orang terakhir: %d.",
            iotHistory.count,
            averageTemperature,
            latestPeople
        )
    }

    func fetchWeatherNoonHistory() async {
        isWeatherLoading = true
        weatherErrorMessage = nil

        defer { isWeatherLoading = false }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current

        do {
            weatherSnapshots = try await weatherService.fetchLastSevenNoonSnapshots(
                latitude: latitude,
                longitude: longitude,
                calendar: calendar
            )
            weatherLastFetchedAt = Date()
        } catch {
            weatherSnapshots = []
            weatherErrorMessage = error.localizedDescription
        }
    }

    func connectIoT() {
        iotErrorMessage = nil
        iotClient.connect()
    }

    func disconnectIoT() {
        iotClient.disconnect()
    }

    func clearIoTHistory() {
        latestIoTSnapshot = nil
        iotHistory.removeAll()
        rawIoTMessages.removeAll()
        iotErrorMessage = nil
    }

    private func bindIoTClient() {
        iotClient.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.iotState = state
            }
        }

        iotClient.onSnapshot = { [weak self] snapshot in
            Task { @MainActor in
                self?.appendIoTSnapshot(snapshot)
            }
        }

        iotClient.onRawMessage = { [weak self] message in
            Task { @MainActor in
                self?.rawIoTMessages.insert(message, at: 0)
                if let count = self?.rawIoTMessages.count, count > 5 {
                    self?.rawIoTMessages.removeLast(count - 5)
                }
            }
        }

        iotClient.onError = { [weak self] message in
            Task { @MainActor in
                self?.iotErrorMessage = message
            }
        }
    }

    private func appendIoTSnapshot(_ snapshot: IoTSensorSnapshot) {
        latestIoTSnapshot = snapshot
        iotHistory.append(snapshot)

        if iotHistory.count > maxIoTHistoryCount {
            iotHistory.removeFirst(iotHistory.count - maxIoTHistoryCount)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func timeLabel(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
