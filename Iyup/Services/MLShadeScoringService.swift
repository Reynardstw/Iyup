import Foundation





struct MLShadeScoringService: Sendable {
    struct Weights: Sendable {
        let shadowForecast: Double
        let expectedLight: Double
        let shadeStability: Double
        let expectedTemperature: Double

        static let interval = Weights(
            shadowForecast: 0.70,
            expectedLight: 0.15,
            shadeStability: 0.10,
            expectedTemperature: 0.05
        )
    }

    private let weights: Weights

    init(weights: Weights = .interval) {
        self.weights = weights
    }

    func lightScore(lux: Double) -> Double {
        interpolate(lux, xs: [0, 1_500, 3_000, 6_000], ys: [1.0, 1.0, 0.5, 0.0])
    }

    func temperatureScore(celsius: Double) -> Double {
        interpolate(celsius, xs: [29, 31, 33], ys: [1.0, 0.75, 0.0])
    }

    func occupancyPenalty(occupancy: Double) -> Double {
        interpolate(
            occupancy,
            xs: [0.30, 0.60, 0.85, 1.0],
            ys: [1.0, 0.75, 0.40, 0.0]
        )
    }

    func shadeStability(timeline: [ShadowTimelineEntry]) -> Double {
        guard timeline.count > 1 else { return 1.0 }

        let flags = timeline.map(\.isShaded)
        let transitions = zip(flags, flags.dropFirst())
            .filter { previous, current in previous != current }
            .count

        return 1.0 - Double(transitions) / Double(flags.count - 1)
    }

    func finalForecastScore(
        shadowForecastScore: Double,
        shadeStability: Double,
        expectedLightScore: Double,
        expectedTemperatureScore: Double,
        occupancyPenalty: Double
    ) -> Double {
        let base = weights.shadowForecast * shadowForecastScore
            + weights.expectedLight * expectedLightScore
            + weights.shadeStability * shadeStability
            + weights.expectedTemperature * expectedTemperatureScore

        return max(0.0, min(1.0, base * occupancyPenalty))
    }

    private func interpolate(
        _ x: Double,
        xs: [Double],
        ys: [Double]
    ) -> Double {
        precondition(xs.count == ys.count && xs.count >= 2)

        if x <= xs[0] { return ys[0] }
        if x >= xs[xs.count - 1] { return ys[ys.count - 1] }

        for index in 1..<xs.count where x <= xs[index] {
            let t = (x - xs[index - 1]) / (xs[index] - xs[index - 1])
            return ys[index - 1] + t * (ys[index] - ys[index - 1])
        }

        return ys[ys.count - 1]
    }
}
