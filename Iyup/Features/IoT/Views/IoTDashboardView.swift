import SwiftUI
import Charts

struct IoTDashboardView: View {
    @State private var viewModel: IoTViewModel

    @MainActor
    init(viewModel: IoTViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @MainActor
    init() {
        self.init(viewModel: IoTViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: viewModel.state.isConnected ? "dot.radiowaves.left.and.right" : "wifi.slash")
                            .font(.system(size: 40))
                            .symbolRenderingMode(.hierarchical)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.state.title)
                                .font(.title3.bold())
                            Text("Topic: sensor/data")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if viewModel.latestSnapshot == nil {
                    Section {
                        ContentUnavailableView(
                            "Belum ada data IoT",
                            systemImage: "sensor.tag.radiowaves.forward",
                            description: Text("Tekan Connect untuk subscribe ke MQTT dan menerima payload ESP32.")
                        )
                    }
                } else {
                    Section("Data Sensor Terakhir") {
                        ForEach(viewModel.rows) { row in
                            LabeledContent(row.label, value: row.value)
                        }
                    }

                    Section("Grafik Live") {
                        IoTChartsView(
                            temperaturePoints: viewModel.temperaturePoints,
                            peoplePoints: viewModel.peoplePoints,
                            humidityPoints: viewModel.humidityPoints,
                            lightPoints: viewModel.lightPoints
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }

                if !viewModel.rawMessages.isEmpty {
                    Section("Raw MQTT") {
                        ForEach(Array(viewModel.rawMessages.enumerated()), id: \.offset) { _, message in
                            Text(message)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                        }
                    }
                }

                Section {
                    HStack {
                        Button(viewModel.state.isConnected ? "Disconnect" : "Connect") {
                            if viewModel.state.isConnected {
                                viewModel.disconnect()
                            } else {
                                viewModel.connect()
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear") {
                            viewModel.clearHistory()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("IoT MQTT")
        }
    }
}

private struct IoTChartsView: View {
    let temperaturePoints: [IoTViewModel.ChartPoint]
    let peoplePoints: [IoTViewModel.ChartPoint]
    let humidityPoints: [IoTViewModel.ChartPoint]
    let lightPoints: [IoTViewModel.ChartPoint]

    var body: some View {
        VStack(spacing: 18) {
            IoTLineChartCard(
                title: "Suhu",
                axisLabel: "°C",
                points: temperaturePoints
            )

            IoTLineChartCard(
                title: "Jumlah Orang",
                axisLabel: "Orang",
                points: peoplePoints
            )

            IoTLineChartCard(
                title: "Kelembapan",
                axisLabel: "%",
                points: humidityPoints
            )

            IoTLineChartCard(
                title: "Cahaya",
                axisLabel: "Lux",
                points: lightPoints
            )
        }
        .padding(.vertical, 4)
    }
}

private struct IoTLineChartCard: View {
    let title: String
    let axisLabel: String
    let points: [IoTViewModel.ChartPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Chart(points) { point in
                LineMark(
                    x: .value("Waktu", point.time),
                    y: .value(axisLabel, point.value)
                )
                PointMark(
                    x: .value("Waktu", point.time),
                    y: .value(axisLabel, point.value)
                )
            }
            .frame(height: 160)
            .chartYAxisLabel(axisLabel)
        }
    }
}

#Preview {
    IoTDashboardView(
        viewModel: IoTViewModel(
            client: PreviewIoTMQTTClient()
        )
    )
}
