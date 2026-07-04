import Foundation

/// Input sensor/current-state values used by the XGBoost Core ML forecast models.
///
/// This file intentionally keeps feature creation separate from Core ML loading.
/// It makes the app easier to test and avoids spreading feature names across the codebase.
public struct ForecastSensorSnapshot: Sendable {
    public let spotID: String
    public let date: Date
    public let isHoliday: Bool

    public let shadowStatus: Double
    public let shadowStatusFuture: Double
    public let sunAltitude: Double
    public let sunAltitudeFuture: Double
    public let cloudCover: Double
    public let cloudForecastFuture: Double
    public let cloudForecast: Double

    public let temp: Double
    public let lux: Double
    public let occupancy: Double

    public init(
        spotID: String,
        date: Date = Date(),
        isHoliday: Bool = false,
        shadowStatus: Double,
        shadowStatusFuture: Double,
        sunAltitude: Double,
        sunAltitudeFuture: Double,
        cloudCover: Double,
        cloudForecastFuture: Double,
        cloudForecast: Double? = nil,
        temp: Double,
        lux: Double,
        occupancy: Double
    ) {
        self.spotID = spotID
        self.date = date
        self.isHoliday = isHoliday
        self.shadowStatus = shadowStatus
        self.shadowStatusFuture = shadowStatusFuture
        self.sunAltitude = sunAltitude
        self.sunAltitudeFuture = sunAltitudeFuture
        self.cloudCover = cloudCover
        self.cloudForecastFuture = cloudForecastFuture
        self.cloudForecast = cloudForecast ?? cloudForecastFuture
        self.temp = temp
        self.lux = lux
        self.occupancy = occupancy
    }
}

/// Optional historical values for short-term models.
///
/// When the app does not have real sensor history yet, use `fallback(current:)`.
/// That keeps the model callable while the real pipeline is being connected.
public struct ForecastHistory: Sendable {
    public let tempLag15m: Double
    public let tempLag30m: Double
    public let tempLag60m: Double
    public let tempRollmean30m: Double
    public let tempTrend: Double

    public let luxLag15m: Double
    public let luxLag30m: Double
    public let luxLag60m: Double
    public let luxRollmean30m: Double
    public let luxTrend: Double

    public let occupancyLag15m: Double
    public let occupancyLag30m: Double
    public let occupancyLag60m: Double
    public let occupancyRollmean30m: Double
    public let occupancyTrend: Double

    public init(
        tempLag15m: Double,
        tempLag30m: Double,
        tempLag60m: Double,
        tempRollmean30m: Double,
        tempTrend: Double,
        luxLag15m: Double,
        luxLag30m: Double,
        luxLag60m: Double,
        luxRollmean30m: Double,
        luxTrend: Double,
        occupancyLag15m: Double,
        occupancyLag30m: Double,
        occupancyLag60m: Double,
        occupancyRollmean30m: Double,
        occupancyTrend: Double
    ) {
        self.tempLag15m = tempLag15m
        self.tempLag30m = tempLag30m
        self.tempLag60m = tempLag60m
        self.tempRollmean30m = tempRollmean30m
        self.tempTrend = tempTrend
        self.luxLag15m = luxLag15m
        self.luxLag30m = luxLag30m
        self.luxLag60m = luxLag60m
        self.luxRollmean30m = luxRollmean30m
        self.luxTrend = luxTrend
        self.occupancyLag15m = occupancyLag15m
        self.occupancyLag30m = occupancyLag30m
        self.occupancyLag60m = occupancyLag60m
        self.occupancyRollmean30m = occupancyRollmean30m
        self.occupancyTrend = occupancyTrend
    }

    public static func fallback(current snapshot: ForecastSensorSnapshot) -> ForecastHistory {
        ForecastHistory(
            tempLag15m: snapshot.temp,
            tempLag30m: snapshot.temp,
            tempLag60m: snapshot.temp,
            tempRollmean30m: snapshot.temp,
            tempTrend: 0,
            luxLag15m: snapshot.lux,
            luxLag30m: snapshot.lux,
            luxLag60m: snapshot.lux,
            luxRollmean30m: snapshot.lux,
            luxTrend: 0,
            occupancyLag15m: snapshot.occupancy,
            occupancyLag30m: snapshot.occupancy,
            occupancyLag60m: snapshot.occupancy,
            occupancyRollmean30m: snapshot.occupancy,
            occupancyTrend: 0
        )
    }
}

public enum ForecastFeatureBuilderError: Error, LocalizedError {
    case unknownSpotID(String)

    public var errorDescription: String? {
        switch self {
        case .unknownSpotID(let spotID):
            return "Unknown spot_id '\(spotID)'. Make sure it exists in the XGBoost spot mapping."
        }
    }
}

public struct ForecastFeatureBuilder: Sendable {
    /// Must match the mapping used during Python training/conversion.
    public let spotMapping: [String: Double]
    private let calendar: Calendar

    public init(
        spotMapping: [String: Double] = [
            "Spot_A": 0,
            "Spot_B": 1,
            "Spot_C": 2,
            "Spot_D": 3,
            "Spot_E": 4,
            "Spot_F": 5
        ],
        calendar: Calendar = .current
    ) {
        self.spotMapping = spotMapping
        self.calendar = calendar
    }

    public func makeShortFeaturePool(
        snapshot: ForecastSensorSnapshot,
        history: ForecastHistory? = nil,
        horizonMinutes: Int
    ) throws -> [String: Double] {
        guard let spotNum = spotMapping[snapshot.spotID] else {
            throw ForecastFeatureBuilderError.unknownSpotID(snapshot.spotID)
        }

        let history = history ?? .fallback(current: snapshot)
        var features = makeCommonFeaturePool(snapshot: snapshot, spotNum: spotNum)

        features["horizon"] = Double(horizonMinutes)
        features["shadow_status_future"] = snapshot.shadowStatusFuture
        features["sun_altitude_future"] = snapshot.sunAltitudeFuture
        features["cloud_forecast_future"] = snapshot.cloudForecastFuture

        features["temp"] = snapshot.temp
        features["temp_lag_15m"] = history.tempLag15m
        features["temp_lag_30m"] = history.tempLag30m
        features["temp_lag_60m"] = history.tempLag60m
        features["temp_rollmean_30m"] = history.tempRollmean30m
        features["temp_trend"] = history.tempTrend

        features["lux"] = snapshot.lux
        features["lux_lag_15m"] = history.luxLag15m
        features["lux_lag_30m"] = history.luxLag30m
        features["lux_lag_60m"] = history.luxLag60m
        features["lux_rollmean_30m"] = history.luxRollmean30m
        features["lux_trend"] = history.luxTrend

        features["occupancy"] = snapshot.occupancy
        features["occupancy_lag_15m"] = history.occupancyLag15m
        features["occupancy_lag_30m"] = history.occupancyLag30m
        features["occupancy_lag_60m"] = history.occupancyLag60m
        features["occupancy_rollmean_30m"] = history.occupancyRollmean30m
        features["occupancy_trend"] = history.occupancyTrend

        return features
    }

    public func makeLongFeaturePool(
        snapshot: ForecastSensorSnapshot,
        leadDays: Int
    ) throws -> [String: Double] {
        guard let spotNum = spotMapping[snapshot.spotID] else {
            throw ForecastFeatureBuilderError.unknownSpotID(snapshot.spotID)
        }

        var features = makeCommonFeaturePool(snapshot: snapshot, spotNum: spotNum)
        features["cloud_forecast"] = snapshot.cloudForecast
        features["lead_days"] = Double(leadDays)
        return features
    }

    private func makeCommonFeaturePool(
        snapshot: ForecastSensorSnapshot,
        spotNum: Double
    ) -> [String: Double] {
        [
            "spot_num": spotNum,
            "hour": hourValue(from: snapshot.date),
            "day_of_week": Double(dayOfWeekPythonStyle(from: snapshot.date)),
            "is_weekend": isWeekend(from: snapshot.date) ? 1 : 0,
            "is_holiday": snapshot.isHoliday ? 1 : 0,
            "shadow_status": snapshot.shadowStatus,
            "sun_altitude": snapshot.sunAltitude,
            "cloud_cover": snapshot.cloudCover
        ]
    }

    private func hourValue(from date: Date) -> Double {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }

    /// Python pandas `.dt.dayofweek`: Monday = 0 ... Sunday = 6.
    private func dayOfWeekPythonStyle(from date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }

    private func isWeekend(from date: Date) -> Bool {
        let day = dayOfWeekPythonStyle(from: date)
        return day >= 5
    }
}
