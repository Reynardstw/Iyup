import SwiftUI

struct ShadeCard: View {
    let scored: MLShadeScoredSpotResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "thermometer.medium")
                    .font(.caption)

                Text(String(format: "%.1f°C", scored.meanPredictedTemperature))
            }

            HStack(spacing: 4) {
                Image(systemName: "sun.max")
                    .font(.caption)

                Text(scored.shadowResult.safetyStatus.rawValue)
            }

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.caption)

                Text(scored.occupancyLabel)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        )
    }
}
