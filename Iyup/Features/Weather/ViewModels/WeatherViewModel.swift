import Foundation
import Observation

@MainActor
@Observable
final class WeatherViewModel {
    let latitude: Double
    let longitude: Double

    private(set) var snapshot: WeatherSnapshot?
    private(set) var isLoading = false
    var errorMessage: String?

    private let weatherService: any WeatherProviding

    init(weatherService: any WeatherProviding, latitude: Double, longitude: Double) {
        self.weatherService = weatherService
        self.latitude = latitude
        self.longitude = longitude
    }

    struct Row: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }

    var rows: [Row] {
        guard let snapshot else { return [] }

        return [
            Row(label: "Diperbarui", value: snapshot.asOf.formatted(date: .abbreviated, time: .shortened)),
            Row(label: "Kondisi", value: snapshot.condition),
            Row(label: "Siang Hari", value: snapshot.isDaylight ? "Ya" : "Tidak"),
            Row(label: "Suhu", value: celsius(snapshot.temperatureCelsius)),
            Row(label: "Terasa Seperti", value: celsius(snapshot.apparentTemperatureCelsius)),
            Row(label: "Titik Embun", value: celsius(snapshot.dewPointCelsius)),
            Row(label: "Kelembapan", value: percent(snapshot.humidity)),
            Row(label: "Tutupan Awan", value: percent(snapshot.cloudCover)),
            Row(label: "Indeks UV", value: "\(snapshot.uvIndexValue) (\(snapshot.uvIndexCategory))"),
            Row(label: "Tekanan", value: String(format: "%.0f mb (%@)", snapshot.pressureMillibars, snapshot.pressureTrend)),
            Row(label: "Jarak Pandang", value: String(format: "%.1f km", snapshot.visibilityMeters / 1000)),
            Row(label: "Curah Hujan", value: String(format: "%.1f mm/j", snapshot.precipitationIntensityMmPerHour)),
            Row(label: "Angin", value: windText(snapshot)),
            Row(label: "Hembusan Angin", value: snapshot.windGustKmh.map { String(format: "%.0f km/j", $0) } ?? "—"),
            Row(label: "Arah Angin", value: String(format: "%.0f° (%@)", snapshot.windDirectionDegrees, snapshot.windCompassDirection))
        ]
    }

    func fetch() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            snapshot = try await weatherService.fetchCurrentWeather(
                latitude: latitude,
                longitude: longitude
            )
        } catch {
            snapshot = nil
            errorMessage = error.localizedDescription
        }
    }

    private func celsius(_ value: Double) -> String {
        String(format: "%.1f°C", value)
    }

    private func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    private func windText(_ snapshot: WeatherSnapshot) -> String {
        String(format: "%.0f km/j", snapshot.windSpeedKmh)
    }
}
