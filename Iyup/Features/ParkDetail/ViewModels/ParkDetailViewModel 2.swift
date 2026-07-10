import Foundation
import Observation

@MainActor
@Observable
final class ParkDetailViewModel {
    private(set) var isLoading = false
    var errorMessage: String?

    var selectedHour: Int {
        didSet { rebuildInfo() }
    }

    private(set) var selectedWeekdayIndex: Int

    private(set) var info: ParkDetailInfo

    private let place: NearbyPlace
    private let staticInfo: ParkStaticInfo
    private let parkLocation: ParkLocation
    private let spots: [ParkSpot]
    private let calculator: ShadowIntervalCalculator
    private let forecastService: any MLShadeEnvironmentForecastProviding
    private let locationViewModel: LocationDistanceViewModel
    private let weatherService: any WeatherProviding

    private var hourlyWeather: [HourlyWeatherPoint] = []
    private var hourlyOccupancy: [Int: Double] = [:]
    private var hourlyShadeFraction: [Int: Double] = [:]

    private let minHour = 6
    private let maxHour = 18

    init(
        place: NearbyPlace,
        parkLocation: ParkLocation,
        spots: [ParkSpot],
        calculator: ShadowIntervalCalculator,
        forecastService: any MLShadeEnvironmentForecastProviding,
        locationViewModel: LocationDistanceViewModel,
        weatherService: any WeatherProviding
    ) {
        self.place = place
        self.staticInfo = ParkStaticDirectory.info(for: place.id)
        self.parkLocation = parkLocation
        self.spots = spots
        self.calculator = calculator
        self.forecastService = forecastService
        self.locationViewModel = locationViewModel
        self.weatherService = weatherService

        let currentHour = Calendar.current.component(.hour, from: Date())
        self.selectedHour = min(maxHour, max(minHour, currentHour))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = parkLocation.timeZone
        self.selectedWeekdayIndex = ParkDetailViewModel.weekdayIndex(for: Date(), calendar: calendar)

        self.info = ParkDetailViewModel.placeholderInfo(staticInfo: staticInfo)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await locationViewModel.locate()

        do {
            hourlyWeather = try await weatherService.fetchHourlyForecast(
                latitude: parkLocation.latitude,
                longitude: parkLocation.longitude,
                startHour: minHour,
                endHour: maxHour
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        await computeHourlyShadeAndOccupancy(referenceDate: Date())
        rebuildInfo()
    }

    func selectWeekday(_ index: Int) async {
        guard index != selectedWeekdayIndex else { return }

        selectedWeekdayIndex = index
        isLoading = true
        defer { isLoading = false }

        let targetDate = date(forWeekdayIndex: index)
        await computeHourlyShadeAndOccupancy(referenceDate: targetDate)
        rebuildInfo()
    }

    private func date(forWeekdayIndex index: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = parkLocation.timeZone

        let today = Date()
        let todayIndex = ParkDetailViewModel.weekdayIndex(for: today, calendar: calendar)
        let dayDelta = index - todayIndex

        return calendar.date(byAdding: .day, value: dayDelta, to: today) ?? today
    }

    private static func weekdayIndex(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return ((weekday + 5) % 7)
    }

    private func computeHourlyShadeAndOccupancy(referenceDate: Date) async {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = parkLocation.timeZone

        var occupancyByHour: [Int: [Double]] = [:]
        var shadeByHour: [Int: [Bool]] = [:]

        for hour in minHour...maxHour {
            guard let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: referenceDate) else {
                continue
            }

            let request = ShadowIntervalRequest(
                location: parkLocation,
                startDate: hourDate,
                endDate: hourDate.addingTimeInterval(60),
                stepMinutes: 1,
                spots: spots
            )

            guard let timelines = try? calculator.calculate(request: request) else { continue }

            for (spot, timeline) in timelines {
                guard let entry = timeline.first else { continue }

                let shadowResult = ShadowIntervalResult(
                    spot: spot,
                    timeline: [entry],
                    shadowForecastScore: entry.isShaded ? 1 : 0,
                    shadeDurationMinutes: entry.isShaded ? entry.durationMinutes : 0,
                    sunExposureMinutes: entry.isShaded ? 0 : entry.durationMinutes,
                    longestDirectSunStreakMinutes: entry.isShaded ? 0 : entry.durationMinutes,
                    firstSunExposureTime: entry.isShaded ? nil : entry.segmentStart,
                    safetyStatus: .alternative,
                    reason: ""
                )

                if let points = try? await forecastService.forecast(
                    for: shadowResult,
                    referenceDate: hourDate,
                    debugRunID: "ParkDetailHourly"
                ), let point = points.first {
                    occupancyByHour[hour, default: []].append(point.occupancy)
                }

                shadeByHour[hour, default: []].append(entry.isShaded)
            }
        }

        hourlyOccupancy = occupancyByHour.mapValues { values in
            values.reduce(0, +) / Double(max(1, values.count))
        }

        hourlyShadeFraction = shadeByHour.mapValues { values in
            Double(values.filter { $0 }.count) / Double(max(1, values.count))
        }
    }

    private func rebuildInfo() {
        let selectedWeather = hourlyWeather.first { $0.hour == selectedHour }
        let temperature = selectedWeather?.temperatureCelsius ?? 31
        let humidity = selectedWeather?.humidity ?? 0.65
        let condition = selectedWeather?.condition ?? "Cerah"
        let symbolName = selectedWeather?.symbolName ?? "sun.max.fill"

        let previewOccupancy = hourlyOccupancy[selectedHour] ?? 0.3

        let outfit = OutfitRecommender.recommend(
            temperatureCelsius: temperature,
            condition: condition,
            hour: selectedHour
        )

        let distanceKm = locationViewModel.distanceMeters.map { Int(($0 / 1000).rounded()) } ?? 0

        info = ParkDetailInfo(
            id: staticInfo.placeID,
            name: staticInfo.name,
            city: staticInfo.city,
            entrance: staticInfo.entrance,
            hoursLabel: staticInfo.hoursLabel,
            isOpen: staticInfo.isOpen,
            openHoursDetail: staticInfo.openHoursDetail,
            address: staticInfo.address,
            distanceKm: distanceKm,
            temperatureCelsius: Int(temperature.rounded()),
            humidityPercent: Int((humidity * 100).rounded()),
            weatherSymbolName: symbolName,
            outfitHeadline: outfit.headline,
            outfitEmojis: outfit.emojis,
            crowdLabel: crowdLabel(for: previewOccupancy),
            recommendedShadeWindow: bestShadeWindow(),
            popularToday: popularSlots(highlightedHour: selectedHour),
            todayIndex: selectedWeekdayIndex
        )
    }

    private func crowdLabel(for occupancy: Double) -> String {
        switch occupancy {
        case ..<0.31:
            return "Not busy"
        case ..<0.61:
            return "Moderate"
        case ..<0.86:
            return "Busy"
        default:
            return "Full"
        }
    }

    private func bestShadeWindow(windowLength: Int = 2) -> String {
        let hours = Array(minHour...maxHour)

        guard hours.count >= windowLength else {
            return "\(String(format: "%02d", minHour)).00 - \(String(format: "%02d", maxHour)).00"
        }

        func comfortScore(hour: Int) -> Double {
            let shade = hourlyShadeFraction[hour] ?? 0.5
            let occupancy = hourlyOccupancy[hour] ?? 0.5
            let temperature = hourlyWeather.first { $0.hour == hour }?.temperatureCelsius ?? 31
            let temperatureComfort = 1.0 - min(1.0, max(0.0, (temperature - 29.0) / 6.0))

            return shade * 0.5 + (1.0 - occupancy) * 0.3 + temperatureComfort * 0.2
        }

        var bestStart = hours[0]
        var bestScore = -1.0

        for startIndex in 0...(hours.count - windowLength) {
            let windowHours = hours[startIndex..<(startIndex + windowLength)]
            let averageScore = windowHours.map(comfortScore).reduce(0, +) / Double(windowLength)

            if averageScore > bestScore {
                bestScore = averageScore
                bestStart = windowHours.first ?? hours[0]
            }
        }

        let endHour = bestStart + windowLength
        return "\(String(format: "%02d", bestStart)).00 - \(String(format: "%02d", endHour)).00"
    }

    private func popularSlots(highlightedHour: Int) -> [PopularSlot] {
        (minHour...maxHour).map { hour in
            PopularSlot(
                hour: hour,
                level: hourlyOccupancy[hour] ?? 0.3,
                isNow: hour == highlightedHour
            )
        }
    }

    private static func placeholderInfo(staticInfo: ParkStaticInfo) -> ParkDetailInfo {
        ParkDetailInfo(
            id: staticInfo.placeID,
            name: staticInfo.name,
            city: staticInfo.city,
            entrance: staticInfo.entrance,
            hoursLabel: staticInfo.hoursLabel,
            isOpen: staticInfo.isOpen,
            openHoursDetail: staticInfo.openHoursDetail,
            address: staticInfo.address,
            distanceKm: 0,
            temperatureCelsius: 31,
            humidityPercent: 65,
            weatherSymbolName: "sun.max.fill",
            outfitHeadline: "Menghitung rekomendasi outfit...",
            outfitEmojis: ["🕶️", "👒", "👟", "🩴"],
            crowdLabel: "Moderate",
            recommendedShadeWindow: "08.00 - 10.00",
            popularToday: (6...18).map { PopularSlot(hour: $0, level: 0.3, isNow: false) },
            todayIndex: 0
        )
    }
}
