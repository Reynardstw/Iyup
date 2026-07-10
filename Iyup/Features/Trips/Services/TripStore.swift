import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TripStore {
    static let shared = TripStore()

    private(set) var trips: [Trip] = []

    private let key = "iyup.savedTrips.v1"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ trip: Trip) {
        trips.insert(trip, at: 0)
        persist()
    }

    func update(_ trip: Trip) {
        guard let idx = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[idx] = trip
        persist()
        TripNotificationScheduler.cancel(for: trip)
        Task { await TripNotificationScheduler.schedule(for: trip) }
    }

    func delete(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(trips) {
            defaults.set(data, forKey: key)
        }
    }
}
