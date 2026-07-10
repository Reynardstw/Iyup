import Foundation
import simd

@MainActor
enum AppComposition {
    static func makeScoreViewModel() -> MLShadeRecommendationViewModel {
        do {
            let viewModel = try makeCoreMLScoreViewModel()
            return viewModel
        } catch {
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

        let location = ParkGeometryCatalog.tamanBenderaPusakaLocation
        let spots = ParkGeometryCatalog.benchSpots
        let treeOccluders = ParkGeometryCatalog.treeOccluders

        let raycastService = GeometryShadowRaycastService(
            occluders: treeOccluders
        )

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

    static func makeParkDetailViewModel(place: NearbyPlace = .tamanBenderaPusaka) -> ParkDetailViewModel {
        let location = ParkGeometryCatalog.tamanBenderaPusakaLocation
        let spots = ParkGeometryCatalog.benchSpots
        let treeOccluders = ParkGeometryCatalog.treeOccluders

        let raycastService = GeometryShadowRaycastService(
            occluders: treeOccluders
        )

        let calculator = ShadowIntervalCalculator(
            sunPositionService: OfficialSunKitSunPositionService(),
            shadowRaycastService: raycastService,
            sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive),
            shadeCoverageThreshold: 0.70,
            benchSampleRadius: 0.50
        )

        let forecastService: any MLShadeEnvironmentForecastProviding
        do {
            forecastService = try MLShadeCoreMLForecastService(calendar: jakartaCalendar)
        } catch {
            forecastService = MLShadeMockEnvironmentForecastService()
        }

        let locationViewModel = LocationDistanceViewModel(
            locationService: CoreLocationUserLocationService(),
            destination: place
        )

        return ParkDetailViewModel(
            place: place,
            parkLocation: location,
            spots: spots,
            calculator: calculator,
            forecastService: forecastService,
            locationViewModel: locationViewModel,
            weatherService: WeatherKitWeatherService()
        )
    }

    static func makePlanTripViewModel() -> PlanTripViewModel {
        let location = ParkGeometryCatalog.tamanBenderaPusakaLocation
        let spots = ParkGeometryCatalog.benchSpots
        let treeOccluders = ParkGeometryCatalog.treeOccluders

        let raycastService = GeometryShadowRaycastService(
            occluders: treeOccluders
        )

        let calculator = ShadowIntervalCalculator(
            sunPositionService: OfficialSunKitSunPositionService(),
            shadowRaycastService: raycastService,
            sunVectorConverter: SunVectorConverter(zAxisDirection: .northPositive),
            shadeCoverageThreshold: 0.70,
            benchSampleRadius: 0.50
        )

        return PlanTripViewModel(
            parkLocation: location,
            spots: spots,
            calculator: calculator
        )
    }
}
