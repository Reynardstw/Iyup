import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var viewModel: AnalyticsViewModel

    @MainActor
    init(viewModel: AnalyticsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @MainActor
    init() {
        self.init(viewModel: AnalyticsViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                weatherControlSection
                weatherChartsSection
                iotControlSection
                iotChartsSection
                rawIoTSection
            }
            .navigationTitle("Analytics")
        }
    }

    private var weatherControlSection: some View {
        Section("Weather Analytics") {
            Text(viewModel.weatherSummaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let weatherLastFetchedAt = viewModel.weatherLastFetchedAt {
                LabeledContent(
                    "Fetch terakhir",
                    value: weatherLastFetchedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }

            if let weatherErrorMessage = viewModel.weatherErrorMessage {
                Text(weatherErrorMessage)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.fetchWeatherNoonHistory() }
            } label: {
                if viewModel.isWeatherLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Fetch Weather 7 Hari Jam 12")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isWeatherLoading)
        }
    }

    @ViewBuilder
    private var weatherChartsSection: some View {
        if !viewModel.weatherSnapshots.isEmpty {
            Section("Grafik Weather") {
                AnalyticsLineChartCard(
                    title: "Suhu Jam 12",
                    subtitle: "1 titik per hari dari WeatherKit",
                    axisLabel: "°C",
                    points: viewModel.weatherTemperaturePoints
                )

                AnalyticsLineChartCard(
                    title: "Kelembapan Jam 12",
                    subtitle: "Persentase kelembapan per hari",
                    axisLabel: "%",
                    points: viewModel.weatherHumidityPoints
                )

                AnalyticsLineChartCard(
                    title: "Tutupan Awan Jam 12",
                    subtitle: "Persentase cloud cover per hari",
                    axisLabel: "%",
                    points: viewModel.weatherCloudCoverPoints
                )

                AnalyticsLineChartCard(
                    title: "Curah Hujan Jam 12",
                    subtitle: "Akumulasi curah hujan pada hourly forecast",
                    axisLabel: "mm",
                    points: viewModel.weatherRainPoints
                )
            }
        }
    }

    private var iotControlSection: some View {
        Section("IoT Analytics") {
            HStack(spacing: 16) {
                Image(systemName: viewModel.iotState.isConnected ? "dot.radiowaves.left.and.right" : "wifi.slash")
                    .font(.system(size: 36))
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.iotState.title)
                        .font(.headline)
                    Text(viewModel.iotSummaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            if let iotErrorMessage = viewModel.iotErrorMessage {
                Text(iotErrorMessage)
                    .foregroundStyle(.red)
            }

            HStack {
                Button(viewModel.iotState.isConnected ? "Disconnect IoT" : "Connect IoT") {
                    if viewModel.iotState.isConnected {
                        viewModel.disconnectIoT()
                    } else {
                        viewModel.connectIoT()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Clear IoT") {
                    viewModel.clearIoTHistory()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var iotChartsSection: some View {
        if !viewModel.iotHistory.isEmpty {
            Section("Grafik IoT") {
                AnalyticsLineChartCard(
                    title: "Suhu ESP32",
                    subtitle: "Data live dari payload MQTT",
                    axisLabel: "°C",
                    points: viewModel.iotTemperaturePoints
                )

                AnalyticsLineChartCard(
                    title: "Jumlah Orang",
                    subtitle: "Data live dari field Orang",
                    axisLabel: "Orang",
                    points: viewModel.iotPeoplePoints
                )

                AnalyticsLineChartCard(
                    title: "Kelembapan ESP32",
                    subtitle: "Data live dari field Kelembapan",
                    axisLabel: "%",
                    points: viewModel.iotHumidityPoints
                )

                AnalyticsLineChartCard(
                    title: "Cahaya LDR",
                    subtitle: "ADC LDR yang sudah dikonversi menjadi lux",
                    axisLabel: "Lux",
                    points: viewModel.iotLightPoints
                )
            }
        }
    }

    @ViewBuilder
    private var rawIoTSection: some View {
        if !viewModel.rawIoTMessages.isEmpty {
            Section("Raw MQTT Terakhir") {
                ForEach(Array(viewModel.rawIoTMessages.enumerated()), id: \.offset) { _, message in
                    Text(message)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct AnalyticsLineChartCard: View {
    let title: String
    let subtitle: String
    let axisLabel: String
    let points: [AnalyticsViewModel.ChartPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if points.isEmpty {
                ContentUnavailableView(
                    "Belum ada data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Chart akan muncul setelah data tersedia.")
                )
                .frame(minHeight: 120)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Waktu", point.label),
                        y: .value(axisLabel, point.value)
                    )
                    PointMark(
                        x: .value("Waktu", point.label),
                        y: .value(axisLabel, point.value)
                    )
                }
                .frame(height: 180)
                .chartYAxisLabel(axisLabel)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AnalyticsView(
        viewModel: AnalyticsViewModel(
            weatherService: PreviewAnalyticsWeatherService(),
            iotClient: PreviewIoTMQTTClient(),
            latitude: -6.2000,
            longitude: 106.8167
        )
    )
}
