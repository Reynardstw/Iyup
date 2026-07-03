import Foundation
import Observation
import simd

@MainActor
@Observable
final class ShadeRecommendationViewModel {
    var results: [ShadowIntervalResult] = []
    var errorMessage: String?
    var isCalculating = false

    var startDate: Date
    var endDate: Date

    private let recommendationEngine: ShadeRecommendationEngine
    private let location: ParkLocation
    private let spots: [ParkSpot]

    init(
        recommendationEngine: ShadeRecommendationEngine,
        location: ParkLocation,
        spots: [ParkSpot],
        startDate: Date,
        endDate: Date
    ) {
        self.recommendationEngine = recommendationEngine
        self.location = location
        self.spots = spots
        self.startDate = startDate
        self.endDate = endDate
    }

    func calculateRecommendation() {
        isCalculating = true
        errorMessage = nil

        defer {
            isCalculating = false
        }

        do {
            let request = ShadowIntervalRequest(
                location: location,
                startDate: startDate,
                endDate: endDate,
                stepMinutes: 15,
                spots: spots
            )

            results = try recommendationEngine.recommend(
                request: request
            )
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
    }
}

extension ShadeRecommendationViewModel {
    static func makePreview() -> ShadeRecommendationViewModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current

        let now = Date()

        let startDate = calendar.date(
            bySettingHour: 15,
            minute: 0,
            second: 0,
            of: now
        ) ?? now

        let endDate = calendar.date(
            bySettingHour: 17,
            minute: 0,
            second: 0,
            of: now
        ) ?? now.addingTimeInterval(7200)

        let location = ParkLocation(
            latitude: -6.2000,
            longitude: 106.8167,
            timeZoneIdentifier: "Asia/Jakarta"
        )

        let spots = [
            ParkSpot(
                id: "spot_a",
                name: "Spot A",
                position: SIMD3<Float>(0.0, 0.1, 0.0)
            ),
            ParkSpot(
                id: "spot_b",
                name: "Spot B",
                position: SIMD3<Float>(3.0, 0.1, 1.0)
            ),
            ParkSpot(
                id: "spot_c",
                name: "Spot C",
                position: SIMD3<Float>(-2.0, 0.1, 4.0)
            )
        ]

        let occluders = [
            ShadowOccluderSphere(
                id: "tree_01",
                center: SIMD3<Float>(2.0, 2.0, 0.0),
                radius: 1.7
            ),
            ShadowOccluderSphere(
                id: "tree_02",
                center: SIMD3<Float>(-1.5, 2.2, 2.5),
                radius: 1.8
            )
        ]

        let raycastService = GeometryShadowRaycastService(
            occluders: occluders
        )

        let sunService = OfficialSunKitSunPositionService()

        let calculator = ShadowIntervalCalculator(
            sunPositionService: sunService,
            shadowRaycastService: raycastService,
            sunVectorConverter: SunVectorConverter(
                zAxisDirection: .northPositive
            )
        )

        let engine = ShadeRecommendationEngine(
            calculator: calculator
        )

        return ShadeRecommendationViewModel(
            recommendationEngine: engine,
            location: location,
            spots: spots,
            startDate: startDate,
            endDate: endDate
        )
    }
}
