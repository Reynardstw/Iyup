import Foundation
import simd

@MainActor
enum AppComposition {
    static func makeScoreViewModel() -> MLShadeRecommendationViewModel {
        do {
            let viewModel = try makeCoreMLScoreViewModel()
            print("✅ [Iyup] USING CORE ML FORECAST SERVICE")
            return viewModel
        } catch {
            print("⚠️ [Iyup] CORE ML FAILED, USING MOCK FORECAST SERVICE")
            print("⚠️ [Iyup] Error: \(error)")
            return makeMockScoreViewModel()
        }
    }

    static func makeCoreMLScoreViewModel() throws -> MLShadeRecommendationViewModel {
        try makeScoreViewModel(
            forecastService: MLShadeCoreMLForecastService(
                calendar: jakartaCalendar
            )
        )
    }

    static func makeMockScoreViewModel() -> MLShadeRecommendationViewModel {
        makeScoreViewModel(
            forecastService: MLShadeMockEnvironmentForecastService()
        )
    }

    private static func makeScoreViewModel(
        forecastService: any MLShadeEnvironmentForecastProviding
    ) -> MLShadeRecommendationViewModel {
        let now = Date()
        let startDate = jakartaCalendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let endDate = jakartaCalendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)
            ?? now.addingTimeInterval(7_200)

        let location = SunExposureProjectionExporter.tamanBenderaPusakaLocation
        let spots = SunExposureProjectionExporter.benchSpots
        let treeOccluders = SunExposureProjectionExporter.treeOccluders

        let raycastService = GeometryShadowRaycastService(
            occluders: treeOccluders
        )

        print("🪑 [Iyup] Bench count: \(spots.count)")
        for spot in spots {
            print("🪑 [Iyup] \(spot.name): x=\(spot.position.x), y=\(spot.position.y), z=\(spot.position.z)")
        }
        print("🌳 [Iyup] Tree occluder count: \(treeOccluders.count)")

        let calculator = ShadowIntervalCalculator(
            sunPositionService: OfficialSunKitSunPositionService(),
            shadowRaycastService: raycastService,
            sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive),
            shadeCoverageThreshold: 0.70,
            benchSampleRadius: 0.50
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
