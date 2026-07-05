import Foundation
import simd







@MainActor
enum MLShadeRecommendationDemoFactory {
    static func makeViewModel() -> MLShadeRecommendationViewModel {
        do {
            let viewModel = try makeCoreMLViewModel()
            print("✅ [MLShade] USING CORE ML MODEL SERVICE")
            return viewModel
        } catch {
            print("⚠️ [MLShade] CORE ML FAILED, USING MOCK SERVICE")
            print("⚠️ [MLShade] Error: \(error)")
            return makeMockViewModel()
        }
    }

    static func makeCoreMLViewModel() throws -> MLShadeRecommendationViewModel {
        try makeViewModel(
            forecastService: MLShadeCoreMLForecastService(
                calendar: jakartaCalendar
            )
        )
    }

    static func makeMockViewModel() -> MLShadeRecommendationViewModel {
        makeViewModel(
            forecastService: MLShadeMockEnvironmentForecastService()
        )
    }

    private static func makeViewModel(
        forecastService: any MLShadeEnvironmentForecastProviding
    ) -> MLShadeRecommendationViewModel {
        let now = Date()
        let startDate = jakartaCalendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let endDate = jakartaCalendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)
            ?? now.addingTimeInterval(7_200)

        let location = ParkLocation(
            latitude: -6.2000,
            longitude: 106.8167,
            timeZoneIdentifier: "Asia/Jakarta"
        )

        
        
        let spots = [
            ParkSpot(id: "Spot_A", name: "Spot A", position: SIMD3<Float>(0.0, 0.1, 0.0)),
            ParkSpot(id: "Spot_B", name: "Spot B", position: SIMD3<Float>(3.0, 0.1, 1.0)),
            ParkSpot(id: "Spot_C", name: "Spot C", position: SIMD3<Float>(-2.0, 0.1, 4.0))
        ]

        let raycastService = GeometryShadowRaycastService(
            occluders: [
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
        )

        let calculator = ShadowIntervalCalculator(
            sunPositionService: OfficialSunKitSunPositionService(),
            shadowRaycastService: raycastService,
            sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive)
        )

        let recommendationEngine = ShadeRecommendationEngine(calculator: calculator)
        let scoringEngine = MLShadeEnvironmentScoringEngine(
            forecastService: forecastService
        )

        return MLShadeRecommendationViewModel(
            recommendationEngine: recommendationEngine,
            scoringEngine: scoringEngine,
            location: location,
            spots: spots,
            startDate: startDate,
            endDate: endDate
        )
    }

    private static var jakartaCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        return calendar
    }
}
