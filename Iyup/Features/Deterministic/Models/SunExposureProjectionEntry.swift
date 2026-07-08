import Foundation

struct SunExposureProjectionEntry: Identifiable, Equatable, Sendable {
    let id = UUID()
    let spotID: String
    let spotName: String
    let sampleDate: Date
    let hourLabel: String
    let sunAltitudeDegrees: Double
    let sunAzimuthDegrees: Double
    let isShaded: Bool
    let shadeCoverage: Double
    let shadedSampleCount: Int
    let totalSampleCount: Int

    var isExposedToSun: Bool {
        !isShaded
    }

    var exposedCoverage: Double {
        max(0.0, min(1.0, 1.0 - shadeCoverage))
    }

    var exposedSampleCount: Int {
        max(0, totalSampleCount - shadedSampleCount)
    }

    var statusLabel: String {
        isShaded ? "TEDUH" : "KENA_MATAHARI"
    }
}
