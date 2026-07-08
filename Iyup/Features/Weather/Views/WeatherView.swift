import SwiftUI

struct WeatherView: View {
    @State private var viewModel: WeatherViewModel

    @MainActor
    init(viewModel: WeatherViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    @MainActor
    init() {
        self.init(
            viewModel: WeatherViewModel(
                weatherService: WeatherKitWeatherService(),
                latitude: -6.2000,
                longitude: 106.8167
            )
        )
    }

    var body: some View {
        NavigationStack {
            List {
                if let snapshot = viewModel.snapshot {
                    Section {
                        HStack(spacing: 16) {
                            Image(systemName: snapshot.symbolName)
                                .font(.system(size: 44))
                                .symbolRenderingMode(.multicolor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: "%.0f°C", snapshot.temperatureCelsius))
                                    .font(.largeTitle.bold())
                                Text(snapshot.condition)
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Semua Data Saat Ini") {
                        ForEach(viewModel.rows) { row in
                            LabeledContent(row.label, value: row.value)
                        }
                    }

                    Section {
                        Text("Data: Apple Weather")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                } else {
                    Section {
                        ContentUnavailableView(
                            "Belum ada data cuaca",
                            systemImage: "cloud.sun",
                            description: Text("Tekan Ambil Data Cuaca untuk memuat kondisi terkini.")
                        )
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.fetch() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Ambil Data Cuaca")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Cuaca")
        }
    }
}

#Preview {
    WeatherView(
        viewModel: WeatherViewModel(
            weatherService: PreviewWeatherService(),
            latitude: -6.2000,
            longitude: 106.8167
        )
    )
}
