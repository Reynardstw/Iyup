import Foundation

enum TripAlertOption: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case atTime = "At time of event"
    case fiveMinutesBefore = "5 minutes before"
    case fifteenMinutesBefore = "15 minutes before"
    case thirtyMinutesBefore = "30 minutes before"
    case oneHourBefore = "1 hour before"
    case oneDayBefore = "1 day before"

    var id: String { rawValue }
}
