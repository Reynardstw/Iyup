import SwiftUI
import MapKit

struct LocationDistanceView: View {
    @State private var viewModel: LocationDistanceViewModel
    @State private var cameraPosition: MapCameraPosition

    @MainActor
    init(viewModel: LocationDistanceViewModel) {
        _viewModel = State(initialValue: viewModel)
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: viewModel.destination.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        )
    }

    @MainActor
    init() {
        self.init(
            viewModel: LocationDistanceViewModel(
                locationService: CoreLocationUserLocationService(),
                destination: .tamanBenderaPusaka
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition) {
                    Marker(viewModel.destination.name, coordinate: viewModel.destination.coordinate)
                        .tint(.green)

                    if let userCoordinate = viewModel.userCoordinate {
                        Marker("Lokasi Saya", systemImage: "location.fill", coordinate: userCoordinate)
                            .tint(.blue)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                summary
            }
            .navigationTitle("Jarak Lokasi")
            .task {
                await viewModel.locate()
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tujuan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.destination.name)
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Jarak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.distanceText ?? "—")
                        .font(.title3.bold())
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await viewModel.locate() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Perbarui Lokasi")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(.thinMaterial)
    }
}

#Preview {
    LocationDistanceView(
        viewModel: LocationDistanceViewModel(
            locationService: PreviewUserLocationService(),
            destination: .tamanBenderaPusaka
        )
    )
}
