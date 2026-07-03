import Foundation

struct ShadowTimelineEntry: Identifiable, Equatable, Sendable {
    let id = UUID()

    let segmentStart: Date
    let segmentEnd: Date
    let sampleDate: Date

    let sunPosition: SunPosition
    let isShaded: Bool

    var durationMinutes: Double {
        segmentEnd.timeIntervalSince(segmentStart) / 60.0
    }
}
