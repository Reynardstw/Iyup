import Foundation
import Observation

@MainActor
@Observable
final class PlanTripViewModel {
    var selectedDate: Date {
        didSet { evaluateShadeCondition() }
    }

    var alertOption: TripAlertOption = .none

    private(set) var shadeConditionText: String

    let parkLocation: ParkLocation

    private let spots: [ParkSpot]
    private let calculator: ShadowIntervalCalculator

    init(
        parkLocation: ParkLocation,
        spots: [ParkSpot],
        calculator: ShadowIntervalCalculator,
        initialDate: Date = Date()
    ) {
        self.parkLocation = parkLocation
        self.spots = spots
        self.calculator = calculator
        self.selectedDate = initialDate
        self.shadeConditionText = "Menghitung kondisi teduh..."

        evaluateShadeCondition()
    }

    private func evaluateShadeCondition() {
        let request = ShadowIntervalRequest(
            location: parkLocation,
            startDate: selectedDate,
            endDate: selectedDate.addingTimeInterval(60),
            stepMinutes: 1,
            spots: spots
        )

        guard let timelines = try? calculator.calculate(request: request) else {
            shadeConditionText = "Kondisi teduh tidak dapat dihitung untuk waktu ini."
            return
        }

        let shadedFlags = timelines.values.compactMap { $0.first?.isShaded }
        let total = shadedFlags.count

        guard total > 0 else {
            shadeConditionText = "Kondisi teduh tidak dapat dihitung untuk waktu ini."
            return
        }

        let shadedCount = shadedFlags.filter { $0 }.count
        let ratio = Double(shadedCount) / Double(total)

        if ratio >= 0.5 {
            shadeConditionText = "Sebagian besar area taman teduh pada waktu ini."
        } else {
            shadeConditionText = "Sebagian area teduh, sebagian terkena matahari."
        }
    }
}
