import Foundation
import UserNotifications

enum TripNotificationScheduler {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    static func schedule(for trip: Trip) async {
        guard let lead = leadTime(for: trip.alertOption) else { return }
        let fireDate = trip.date.addingTimeInterval(-lead)
        guard fireDate > Date() else { return }

        await requestAuthorizationIfNeeded()

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trip Reminder"
        content.body = "Your trip to \(trip.parkName) is coming up."
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: trip.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    static func cancel(for trip: Trip) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [trip.id.uuidString])
    }

    private static func leadTime(for option: TripAlertOption) -> TimeInterval? {
        switch option {
        case .none:                 return nil
        case .atTime:               return 0
        case .fiveMinutesBefore:    return 5 * 60
        case .fifteenMinutesBefore: return 15 * 60
        case .thirtyMinutesBefore:  return 30 * 60
        case .oneHourBefore:        return 60 * 60
        case .oneDayBefore:         return 24 * 60 * 60
        }
    }
}
