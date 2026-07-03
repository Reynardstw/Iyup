import Foundation
import simd

struct ShadowIntervalCalculator {
    private let sunPositionService: SunPositionProviding
    private let shadowRaycastService: ShadowRaycastProviding
    private let sampler: DateIntervalSampler
    private let sunVectorConverter: SunVectorConverter

    init(
        sunPositionService: SunPositionProviding,
        shadowRaycastService: ShadowRaycastProviding,
        sampler: DateIntervalSampler = DateIntervalSampler(),
        sunVectorConverter: SunVectorConverter = SunVectorConverter()
    ) {
        self.sunPositionService = sunPositionService
        self.shadowRaycastService = shadowRaycastService
        self.sampler = sampler
        self.sunVectorConverter = sunVectorConverter
    }

    func calculate(
        request: ShadowIntervalRequest
    ) throws -> [ParkSpot: [ShadowTimelineEntry]] {
        guard !request.spots.isEmpty else {
            throw ShadowCalculationError.emptySpots
        }

        let segments = try sampler.makeSegments(
            startDate: request.startDate,
            endDate: request.endDate,
            stepMinutes: request.stepMinutes
        )

        var timelines: [ParkSpot: [ShadowTimelineEntry]] = Dictionary(
            uniqueKeysWithValues: request.spots.map { ($0, []) }
        )

        for segment in segments {
            let sampleDate = segment.midpoint

            let sunPosition = try sunPositionService.position(
                at: sampleDate,
                location: request.location
            )

            let sunDirection = sunVectorConverter.directionVector(
                from: sunPosition
            )

            for spot in request.spots {
                let isShaded: Bool

                if sunPosition.isAboveHorizon {
                    isShaded = try shadowRaycastService.isPointShaded(
                        point: spot.position,
                        sunDirection: sunDirection
                    )
                } else {
                    // At night or below the horizon, there is no direct sunlight.
                    isShaded = true
                }

                let entry = ShadowTimelineEntry(
                    segmentStart: segment.start,
                    segmentEnd: segment.end,
                    sampleDate: sampleDate,
                    sunPosition: sunPosition,
                    isShaded: isShaded
                )

                timelines[spot, default: []].append(entry)
            }
        }

        return timelines
    }
}
