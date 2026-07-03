import Foundation

struct DateIntervalSegment: Identifiable, Equatable, Sendable {
    let id = UUID()

    let start: Date
    let end: Date

    var midpoint: Date {
        start.addingTimeInterval(end.timeIntervalSince(start) / 2.0)
    }

    var durationMinutes: Double {
        end.timeIntervalSince(start) / 60.0
    }
}

struct DateIntervalSampler {
    func makeSegments(
        startDate: Date,
        endDate: Date,
        stepMinutes: Int
    ) throws -> [DateIntervalSegment] {
        guard endDate > startDate else {
            throw ShadowCalculationError.invalidDateInterval
        }

        guard stepMinutes > 0 else {
            throw ShadowCalculationError.invalidStepMinutes
        }

        let stepSeconds = TimeInterval(stepMinutes * 60)
        var segments: [DateIntervalSegment] = []

        var currentStart = startDate

        while currentStart < endDate {
            let proposedEnd = currentStart.addingTimeInterval(stepSeconds)
            let currentEnd = min(proposedEnd, endDate)

            segments.append(
                DateIntervalSegment(
                    start: currentStart,
                    end: currentEnd
                )
            )

            currentStart = currentEnd
        }

        return segments
    }
}
