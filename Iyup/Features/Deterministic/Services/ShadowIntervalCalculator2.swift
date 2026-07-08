import Foundation
import simd

struct ShadowIntervalCalculator {
    private let sunPositionService: SunPositionProviding
    private let shadowRaycastService: ShadowRaycastProviding
    private let sampler: DateIntervalSampler
    private let sunVectorConverter: SunVectorConverter
    private let shadeCoverageThreshold: Double
    private let benchSampleRadius: Float

    init(
        sunPositionService: SunPositionProviding,
        shadowRaycastService: ShadowRaycastProviding,
        sampler: DateIntervalSampler = DateIntervalSampler(),
        sunVectorConverter: SunVectorConverter = SunVectorConverter(),
        shadeCoverageThreshold: Double = 0.70,
        benchSampleRadius: Float = 0.50
    ) {
        self.sunPositionService = sunPositionService
        self.shadowRaycastService = shadowRaycastService
        self.sampler = sampler
        self.sunVectorConverter = sunVectorConverter
        self.shadeCoverageThreshold = shadeCoverageThreshold
        self.benchSampleRadius = benchSampleRadius
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
                    isShaded = try isSpotShadedByCoverage(
                        spot: spot,
                        sunDirection: sunDirection
                    )
                } else {
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

    private func isSpotShadedByCoverage(
        spot: ParkSpot,
        sunDirection: SIMD3<Float>
    ) throws -> Bool {
        let samplePoints = benchSamplePoints(for: spot.position)
        var shadedSampleCount = 0

        for point in samplePoints {
            if try shadowRaycastService.isPointShaded(
                point: point,
                sunDirection: sunDirection
            ) {
                shadedSampleCount += 1
            }
        }

        let shadeCoverage = Double(shadedSampleCount) / Double(samplePoints.count)
        return shadeCoverage >= shadeCoverageThreshold
    }

    private func benchSamplePoints(for center: SIMD3<Float>) -> [SIMD3<Float>] {
        Self.benchSampleOffsets(radius: benchSampleRadius).map { offset in
            center + offset
        }
    }

    private static func benchSampleOffsets(radius: Float) -> [SIMD3<Float>] {
        let diagonal = radius * 0.70710678

        return [
            SIMD3<Float>(0.0, 0.0, 0.0),
            SIMD3<Float>(radius, 0.0, 0.0),
            SIMD3<Float>(-radius, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, radius),
            SIMD3<Float>(0.0, 0.0, -radius),
            SIMD3<Float>(diagonal, 0.0, diagonal),
            SIMD3<Float>(diagonal, 0.0, -diagonal),
            SIMD3<Float>(-diagonal, 0.0, diagonal),
            SIMD3<Float>(-diagonal, 0.0, -diagonal)
        ]
    }
}
