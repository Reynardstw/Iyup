import Foundation

struct ShadeRecommendationEngine {
    private let calculator: ShadowIntervalCalculator

    private let recommendedThreshold: Double
    private let alternativeThreshold: Double
    private let maximumRecommendedDirectSunStreakMinutes: Double

    init(
        calculator: ShadowIntervalCalculator,
        recommendedThreshold: Double = 0.80,
        alternativeThreshold: Double = 0.50,
        maximumRecommendedDirectSunStreakMinutes: Double = 15.0
    ) {
        self.calculator = calculator
        self.recommendedThreshold = recommendedThreshold
        self.alternativeThreshold = alternativeThreshold
        self.maximumRecommendedDirectSunStreakMinutes = maximumRecommendedDirectSunStreakMinutes
    }

    func recommend(
        request: ShadowIntervalRequest
    ) throws -> [ShadowIntervalResult] {
        let timelines = try calculator.calculate(request: request)

        let results = timelines.map { spot, timeline in
            makeResult(
                spot: spot,
                timeline: timeline
            )
        }

        return results.sorted { lhs, rhs in
            if lhs.safetyStatus.rankPriority != rhs.safetyStatus.rankPriority {
                return lhs.safetyStatus.rankPriority < rhs.safetyStatus.rankPriority
            }

            if lhs.shadowForecastScore != rhs.shadowForecastScore {
                return lhs.shadowForecastScore > rhs.shadowForecastScore
            }

            if lhs.shadeDurationMinutes != rhs.shadeDurationMinutes {
                return lhs.shadeDurationMinutes > rhs.shadeDurationMinutes
            }

            return lhs.longestDirectSunStreakMinutes < rhs.longestDirectSunStreakMinutes
        }
    }

    private func makeResult(
        spot: ParkSpot,
        timeline: [ShadowTimelineEntry]
    ) -> ShadowIntervalResult {
        let totalDuration = timeline.reduce(0.0) { partialResult, entry in
            partialResult + entry.durationMinutes
        }

        let shadeDuration = timeline.reduce(0.0) { partialResult, entry in
            partialResult + (entry.isShaded ? entry.durationMinutes : 0.0)
        }

        let sunExposureDuration = totalDuration - shadeDuration

        let score = totalDuration > 0
            ? shadeDuration / totalDuration
            : 0.0

        let longestDirectSunStreak = calculateLongestDirectSunStreakMinutes(
            timeline: timeline
        )

        let firstSunExposureTime = timeline.first {
            !$0.isShaded
        }?.segmentStart

        let status = evaluateStatus(
            score: score,
            longestDirectSunStreak: longestDirectSunStreak
        )

        let reason = makeReason(
            status: status,
            shadeDuration: shadeDuration,
            totalDuration: totalDuration,
            longestDirectSunStreak: longestDirectSunStreak,
            firstSunExposureTime: firstSunExposureTime
        )

        return ShadowIntervalResult(
            spot: spot,
            timeline: timeline,
            shadowForecastScore: score,
            shadeDurationMinutes: shadeDuration,
            sunExposureMinutes: sunExposureDuration,
            longestDirectSunStreakMinutes: longestDirectSunStreak,
            firstSunExposureTime: firstSunExposureTime,
            safetyStatus: status,
            reason: reason
        )
    }

    private func evaluateStatus(
        score: Double,
        longestDirectSunStreak: Double
    ) -> ShadowSafetyStatus {
        if score >= 0.999 {
            return .fullySafe
        }

        if score >= recommendedThreshold &&
            longestDirectSunStreak <= maximumRecommendedDirectSunStreakMinutes {
            return .recommended
        }

        if score >= alternativeThreshold {
            return .alternative
        }

        return .unsafe
    }

    private func calculateLongestDirectSunStreakMinutes(
        timeline: [ShadowTimelineEntry]
    ) -> Double {
        var currentStreak = 0.0
        var longestStreak = 0.0

        for entry in timeline {
            if entry.isShaded {
                currentStreak = 0.0
            } else {
                currentStreak += entry.durationMinutes
                longestStreak = max(longestStreak, currentStreak)
            }
        }

        return longestStreak
    }

    private func makeReason(
        status: ShadowSafetyStatus,
        shadeDuration: Double,
        totalDuration: Double,
        longestDirectSunStreak: Double,
        firstSunExposureTime: Date?
    ) -> String {
        let shadeText = "\(Int(shadeDuration.rounded()))/\(Int(totalDuration.rounded())) menit"

        switch status {
        case .fullySafe:
            return "Spot ini aman penuh karena tetap teduh selama \(shadeText)."

        case .recommended:
            return "Spot ini direkomendasikan karena mayoritas interval tetap teduh, dengan durasi teduh \(shadeText)."

        case .alternative:
            if let firstSunExposureTime {
                let timeText = formatTime(firstSunExposureTime)
                return "Spot ini alternatif karena masih teduh \(shadeText), tetapi mulai terkena matahari sekitar \(timeText)."
            } else {
                return "Spot ini alternatif karena durasi teduh \(shadeText), tetapi score belum cukup untuk rekomendasi utama."
            }

        case .unsafe:
            if let firstSunExposureTime {
                let timeText = formatTime(firstSunExposureTime)
                return "Spot ini tidak aman dari matahari karena mulai terkena matahari sekitar \(timeText), dengan paparan terpanjang \(Int(longestDirectSunStreak.rounded())) menit."
            } else {
                return "Spot ini tidak aman dari matahari karena durasi teduh hanya \(shadeText)."
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
