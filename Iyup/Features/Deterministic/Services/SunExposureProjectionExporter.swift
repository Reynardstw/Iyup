import Foundation
import simd

struct SunExposureProjectionExporter {
    private let location: ParkLocation
    private let spots: [ParkSpot]
    private let raycastService: ShadowRaycastProviding
    private let sunPositionService: SunPositionProviding
    private let sunVectorConverter: SunVectorConverter
    private let calendar: Calendar
    private let formatter: DateFormatter
    private let shadeCoverageThreshold: Double
    private let benchSampleRadius: Float

    init(
        location: ParkLocation = Self.tamanBenderaPusakaLocation,
        spots: [ParkSpot] = Self.benchSpots,
        occluders: [ShadowOccluderSphere] = Self.treeOccluders,
        sunPositionService: SunPositionProviding = OfficialSunKitSunPositionService(),
        sunVectorConverter: SunVectorConverter = SunVectorConverter(zAxisDirection: .northPositive),
        calendar: Calendar = Self.jakartaCalendar,
        shadeCoverageThreshold: Double = 0.70,
        benchSampleRadius: Float = 0.50
    ) {
        self.location = location
        self.spots = spots
        self.raycastService = GeometryShadowRaycastService(occluders: occluders)
        self.sunPositionService = sunPositionService
        self.sunVectorConverter = sunVectorConverter
        self.calendar = calendar
        self.shadeCoverageThreshold = shadeCoverageThreshold
        self.benchSampleRadius = benchSampleRadius

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.formatter = formatter
    }

    func generate(
        date: Date,
        startHour: Int = 6,
        endHour: Int = 18,
        stepMinutes: Int = 15,
        includeEndTime: Bool = true
    ) throws -> [SunExposureProjectionEntry] {
        guard stepMinutes > 0 else {
            throw ShadowCalculationError.invalidStepMinutes
        }

        guard let startDate = calendar.date(
            bySettingHour: startHour,
            minute: 0,
            second: 0,
            of: date
        ), let endDate = calendar.date(
            bySettingHour: endHour,
            minute: 0,
            second: 0,
            of: date
        ), endDate >= startDate else {
            throw ShadowCalculationError.invalidDateInterval
        }

        let stepSeconds = TimeInterval(stepMinutes * 60)
        var sampleDate = startDate
        var entries: [SunExposureProjectionEntry] = []

        while (includeEndTime ? sampleDate <= endDate : sampleDate < endDate) {
            let sunPosition = try sunPositionService.position(
                at: sampleDate,
                location: location
            )

            let sunDirection = sunVectorConverter.directionVector(
                from: sunPosition
            )

            let hourLabel = Self.hourLabel(
                for: sampleDate,
                calendar: calendar
            )

            for spot in spots {
                let coverage = try evaluateShadeCoverage(
                    for: spot,
                    sunDirection: sunDirection,
                    sunIsAboveHorizon: sunPosition.isAboveHorizon
                )

                let isShaded = coverage.shadeCoverage >= shadeCoverageThreshold

                entries.append(
                    SunExposureProjectionEntry(
                        spotID: spot.id,
                        spotName: spot.name,
                        sampleDate: sampleDate,
                        hourLabel: hourLabel,
                        sunAltitudeDegrees: sunPosition.altitudeDegrees,
                        sunAzimuthDegrees: sunPosition.azimuthDegrees,
                        isShaded: isShaded,
                        shadeCoverage: coverage.shadeCoverage,
                        shadedSampleCount: coverage.shadedSampleCount,
                        totalSampleCount: coverage.totalSampleCount
                    )
                )
            }

            sampleDate = sampleDate.addingTimeInterval(stepSeconds)
        }

        return entries
    }

    func makeCSV(entries: [SunExposureProjectionEntry]) -> String {
        var rows = [
            "sample_time,spot_id,spot_name,is_exposed_to_sun,is_shaded,status,sun_altitude_deg,sun_azimuth_deg,shade_coverage,exposed_coverage,shaded_sample_count,exposed_sample_count,total_sample_count"
        ]

        rows += entries.map { entry in
            [
                csvEscape(formatter.string(from: entry.sampleDate)),
                csvEscape(entry.spotID),
                csvEscape(entry.spotName),
                entry.isExposedToSun ? "1" : "0",
                entry.isShaded ? "1" : "0",
                csvEscape(entry.statusLabel),
                String(format: "%.4f", entry.sunAltitudeDegrees),
                String(format: "%.4f", entry.sunAzimuthDegrees),
                String(format: "%.4f", entry.shadeCoverage),
                String(format: "%.4f", entry.exposedCoverage),
                "\(entry.shadedSampleCount)",
                "\(entry.exposedSampleCount)",
                "\(entry.totalSampleCount)"
            ].joined(separator: ",")
        }

        return rows.joined(separator: "\n")
    }

    func writeCSV(
        entries: [SunExposureProjectionEntry],
        fileName: String = "sun_exposure_projection.csv"
    ) throws -> URL {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)
        let csv = makeCSV(entries: entries)

        try csv.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8
        )

        return fileURL
    }

    private struct ShadeCoverageEvaluation {
        let shadeCoverage: Double
        let shadedSampleCount: Int
        let totalSampleCount: Int
    }

    private func evaluateShadeCoverage(
        for spot: ParkSpot,
        sunDirection: SIMD3<Float>,
        sunIsAboveHorizon: Bool
    ) throws -> ShadeCoverageEvaluation {
        let samplePoints = benchSamplePoints(for: spot.position)

        guard sunIsAboveHorizon else {
            return ShadeCoverageEvaluation(
                shadeCoverage: 1.0,
                shadedSampleCount: samplePoints.count,
                totalSampleCount: samplePoints.count
            )
        }

        var shadedSampleCount = 0
        for point in samplePoints {
            if try raycastService.isPointShaded(
                point: point,
                sunDirection: sunDirection
            ) {
                shadedSampleCount += 1
            }
        }

        let shadeCoverage = Double(shadedSampleCount) / Double(samplePoints.count)

        return ShadeCoverageEvaluation(
            shadeCoverage: shadeCoverage,
            shadedSampleCount: shadedSampleCount,
            totalSampleCount: samplePoints.count
        )
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

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func hourLabel(
        for date: Date,
        calendar: Calendar
    ) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }
}

extension SunExposureProjectionExporter {
    static var jakartaCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        return calendar
    }

    static var demoDate: Date {
        var components = DateComponents()
        components.calendar = jakartaCalendar
        components.timeZone = jakartaCalendar.timeZone
        components.year = 2026
        components.month = 3
        components.day = 7
        components.hour = 0
        components.minute = 0
        components.second = 0
        return components.date ?? Date()
    }

    static let tamanBenderaPusakaLocation = ParkLocation(
        latitude: -6.245542,
        longitude: 106.794547,
        timeZoneIdentifier: "Asia/Jakarta"
    )

    static let benchSpots: [ParkSpot] = [
        ParkSpot(id: "Bench1", name: "Bench1", position: SIMD3<Float>(-14.2482, -5.9586, 25.3902)),
        ParkSpot(id: "Bench2", name: "Bench2", position: SIMD3<Float>(-3.4660, -6.1398, 69.2860)),
        ParkSpot(id: "Bench3", name: "Bench3", position: SIMD3<Float>(-0.9488, -5.7704, 44.1478)),
        ParkSpot(id: "Bench4", name: "Bench4", position: SIMD3<Float>(13.2469, -6.0049, -25.4502)),
        ParkSpot(id: "Bench5", name: "Bench5", position: SIMD3<Float>(-4.0655, -6.1766, -13.6455)),
    ]

    static let treeOccluders: [ShadowOccluderSphere] = [
        ShadowOccluderSphere(id: "Tree_019", center: SIMD3<Float>(0.0000, 0.0000, 0.0000), radius: 0.0000),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_024", center: SIMD3<Float>(15.0391, -3.4241, -25.2713), radius: 1.6207),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_025", center: SIMD3<Float>(16.6991, -4.0395, -21.2016), radius: 1.6207),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_026", center: SIMD3<Float>(11.1420, -4.0289, -31.2933), radius: 1.3347),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_027", center: SIMD3<Float>(10.0742, -3.2012, -30.4990), radius: 1.6207),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_028", center: SIMD3<Float>(11.6796, -3.4385, -27.8338), radius: 1.6207),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_030", center: SIMD3<Float>(13.7708, -2.8881, -30.9341), radius: 1.9286),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_031", center: SIMD3<Float>(18.2485, -4.3492, -23.2609), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_032", center: SIMD3<Float>(18.8066, -4.3492, -24.7585), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_034", center: SIMD3<Float>(17.5015, -3.6241, -18.4983), radius: 1.9654),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_035", center: SIMD3<Float>(14.9278, -4.2018, -14.8136), radius: 1.6041),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_036", center: SIMD3<Float>(14.2780, -2.9223, -10.9725), radius: 2.1181),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_037", center: SIMD3<Float>(12.6353, -1.8036, -6.8964), radius: 2.6196),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_038", center: SIMD3<Float>(11.1055, -3.4214, -2.9855), radius: 1.7628),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_039", center: SIMD3<Float>(8.8458, -2.2307, 1.0929), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_040", center: SIMD3<Float>(18.1558, -3.5154, -28.1164), radius: 1.8921),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_041", center: SIMD3<Float>(14.4974, -2.6850, -28.6138), radius: 2.1157),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_047", center: SIMD3<Float>(6.2349, -3.0139, 3.9815), radius: 1.7942),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_048", center: SIMD3<Float>(5.6525, -3.2316, 9.5073), radius: 1.6416),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_049", center: SIMD3<Float>(3.4318, -2.7792, 14.2167), radius: 2.0454),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_057", center: SIMD3<Float>(-0.6253, -3.7216, 56.3382), radius: 1.8285),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_058", center: SIMD3<Float>(-1.1523, -3.4198, 59.7718), radius: 2.0696),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_059", center: SIMD3<Float>(-1.1028, -3.1690, 67.7213), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_060", center: SIMD3<Float>(-0.5429, -4.0068, 69.7004), radius: 1.7722),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_061", center: SIMD3<Float>(-7.7218, -2.4033, 78.1869), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_062", center: SIMD3<Float>(-3.0164, -2.7548, 79.1981), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_063", center: SIMD3<Float>(-6.3463, -3.1542, 80.1582), radius: 2.0208),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_064", center: SIMD3<Float>(-9.7030, -3.4304, 80.0007), radius: 1.7891),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_087", center: SIMD3<Float>(-3.6779, -5.1130, 76.9349), radius: 1.0555),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_088", center: SIMD3<Float>(-0.9533, -3.2485, 77.6643), radius: 1.9907),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_089", center: SIMD3<Float>(-1.9145, -2.5200, 74.4495), radius: 2.2722),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_090", center: SIMD3<Float>(-1.7476, -2.2715, 71.6392), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_091", center: SIMD3<Float>(-1.0228, -3.0082, 63.7583), radius: 2.2034),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_092", center: SIMD3<Float>(6.9516, -2.2048, 0.1982), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_093", center: SIMD3<Float>(5.9513, -3.6267, 5.9430), radius: 1.3394),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_094", center: SIMD3<Float>(4.3164, -1.7981, 10.0400), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_095", center: SIMD3<Float>(2.7585, -3.6862, 16.5278), radius: 1.6717),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_096", center: SIMD3<Float>(2.2985, -2.4545, 13.1042), radius: 2.2063),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_097", center: SIMD3<Float>(2.2873, -3.4412, 19.0344), radius: 1.9048),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_098", center: SIMD3<Float>(-3.0213, -2.6873, 57.4034), radius: 2.1854),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_099", center: SIMD3<Float>(-4.3931, -3.2853, 61.5903), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_100", center: SIMD3<Float>(-2.3428, -2.7089, 65.9717), radius: 2.3870),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_101", center: SIMD3<Float>(-6.0884, -3.3510, -9.4868), radius: 1.7903),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_102", center: SIMD3<Float>(-6.8163, -3.0874, -13.8030), radius: 1.7903),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_103", center: SIMD3<Float>(-5.4860, -2.9989, -11.3060), radius: 1.7903),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_104", center: SIMD3<Float>(-7.0486, -3.3883, -8.0103), radius: 1.7903),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_105", center: SIMD3<Float>(-5.4875, -3.4080, -15.8015), radius: 1.7903),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_106", center: SIMD3<Float>(-8.6493, -3.9105, 8.5093), radius: 1.1228),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_107", center: SIMD3<Float>(-8.4104, -4.5412, 7.7958), radius: 0.7826),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_108", center: SIMD3<Float>(-8.1293, -4.4051, 6.1074), radius: 0.8467),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_109", center: SIMD3<Float>(-7.4129, -4.5124, 7.0201), radius: 1.0800),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_110", center: SIMD3<Float>(-9.8347, -4.0669, 9.9710), radius: 1.0788),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_111", center: SIMD3<Float>(-8.9579, -4.5815, 5.2808), radius: 0.7826),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_112", center: SIMD3<Float>(-8.3444, -4.5954, 4.3643), radius: 0.7826),
        ShadowOccluderSphere(id: "Tree_019_Mat_tree_0_113", center: SIMD3<Float>(-9.5978, -4.1090, 11.7307), radius: 1.0788)
    ]
}
