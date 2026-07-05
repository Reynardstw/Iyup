import Foundation

struct ShadowIntervalRequest: Equatable, Sendable {
    let location: ParkLocation
    let startDate: Date
    let endDate: Date
    let stepMinutes: Int
    let spots: [ParkSpot]

    init(
        location: ParkLocation,
        startDate: Date,
        endDate: Date,
        stepMinutes: Int = 15,
        spots: [ParkSpot]
    ) {
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.stepMinutes = stepMinutes
        self.spots = spots
    }
}
