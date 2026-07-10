import SwiftUI
import RealityKit
import Foundation

enum ShadeMapDisplayMode: Equatable {
    case main
    case detail
    case planTrip

    var isPlanTripMini: Bool {
        self == .planTrip
    }
}

@Observable
class ShadeMapViewModel {
    // MARK: - Main state
    var hour: Double = 10
    var showDetail = false
    var currentParkIndex = 0
    var selectedDate = Date()
    var showCalendar = false

    // MARK: - Map interaction state
    var selectedSpot: ShadeSpot? = nil
    var tapLocation: CGPoint? = nil
    var selectedPin: Entity? = nil

    // MARK: - Scene + scoring dependencies
    var scene = ParkScene()
    var scoreViewModel = AppComposition.makeScoreViewModel()

    // MARK: - Park detail + plan trip dependencies
    var parkDetailViewModel = AppComposition.makeParkDetailViewModel()
    var planTripViewModel = AppComposition.makePlanTripViewModel()

    // MARK: - Sheet + Plan Trip state
    var showSheet = false
    var showPlanTrip = false
    var selectedTripForEditing: Trip? = nil
    var sheetDetent: PresentationDetent = .height(73)
    var shadeMapReady = false
    var mapDisplayMode: ShadeMapDisplayMode = .main
    var isSyncingSharedDate = false

    // MARK: - UI constants used by ShadeMapView
    let peekDetent = PresentationDetent.height(73)
    let midDetent = PresentationDetent.fraction(0.5)
    let largeDetent = PresentationDetent.large

    let planTripMapHeight: CGFloat = 132
    let planTripMapTopPadding: CGFloat = 204
    let planTripMapReservedHeight: CGFloat = 150

    let weatherBadgeBottomPadding: CGFloat = 82
    let timeSliderBottomPadding: CGFloat = 52

    var floatingControlsOpacity: Double { 1 }

    // MARK: - Park data
    let parkLocation = ParkLocation(
        latitude: -6.245542,
        longitude: 106.794547,
        timeZoneIdentifier: "Asia/Jakarta"
    )

    let parkList: [ParkModel] = [
        ParkModel(
            name: "Taman Bendera Pusaka",
            description: "South Jakarta | FREE | Open 24 hour",
            distanceInfo: "31km from you • ETA 1h 2m",
            isMapped: true
        ),
        ParkModel(
            name: "Taman EcoPark",
            description: "East Jakarta | FREE | Open 24 hour",
            distanceInfo: "12km from you • ETA 25m",
            isMapped: false
        )
    ]

    var currentPark: ParkModel {
        parkList[currentParkIndex]
    }

    var sun: SunPosition {
        scene.sunPosition(hour: hour, location: parkLocation)
    }

    // MARK: - Debug helper
    func ms(_ t0: CFAbsoluteTime) -> String {
        String(format: "%.1fms", (CFAbsoluteTimeGetCurrent() - t0) * 1000)
    }

    // MARK: - Carousel actions
    func nextPark() {
        currentParkIndex = (currentParkIndex + 1) % parkList.count
    }

    func previousPark() {
        currentParkIndex = (currentParkIndex - 1 + parkList.count) % parkList.count
    }

    // MARK: - Lifecycle / loading
    func loadParkDetail() async {
        let t0 = CFAbsoluteTimeGetCurrent()
        await parkDetailViewModel.load()
        print("⏱[task] parkDetailVM.load took \(ms(t0))")
    }

    // MARK: - Detail mode
    func handleViewDetails() {
        guard currentPark.isMapped else { return }

        let t0 = CFAbsoluteTimeGetCurrent()
        print("⏱[VD] tap start")

        let now = Date()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta")!

        let comp = cal.dateComponents([.hour, .minute], from: now)
        let currentHour = comp.hour ?? 0
        let currentMinute = comp.minute ?? 0

        let totalMinutes = (currentHour * 60) + currentMinute
        let roundedMinutes = Int((Double(totalMinutes) / 15.0).rounded()) * 15
        let clampedMinutes = min(18 * 60, max(6 * 60, roundedMinutes))

        let finalHour = clampedMinutes / 60
        let finalMinute = clampedMinutes % 60

        guard let roundedDate = cal.date(
            bySettingHour: finalHour,
            minute: finalMinute,
            second: 0,
            of: now
        ) else { return }

        let currentHourSlider = Double(finalHour) + (Double(finalMinute) / 60.0)

        isSyncingSharedDate = true
        selectedDate = roundedDate
        hour = currentHourSlider
        parkDetailViewModel.selectedHour = min(18, max(6, Int(currentHourSlider.rounded())))
        planTripViewModel.selectedDate = roundedDate

        print("⏱[VD] before applyMapDisplayMode(.detail) (+\(ms(t0)))")
        applyMapDisplayMode(.detail, duration: 1.0)
        print("⏱[VD] after applyMapDisplayMode(.detail) (+\(ms(t0)))")

        scene.showShadeSpots()
        print("⏱[VD] after showShadeSpots (+\(ms(t0)))")

        showDetail = true
        showSheet = true
        print("⏱[VD] after set flags (+\(ms(t0)))")

        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.recalcAndGlow(for: currentHourSlider, date: roundedDate)
            self.isSyncingSharedDate = false
        }

        print("⏱[VD] tap end sync-block (+\(ms(t0)))")
    }

    func closeDetail() {
        selectedSpot = nil
        scene.hideShadeSpots()
        applyMapDisplayMode(.main, duration: 1.0)
        showDetail = false
        showSheet = false
        showPlanTrip = false
    }

    // MARK: - Plan Trip mode
    func openPlanTripFromSheet() {
        planTripViewModel.selectedDate = selectedDate
        showSheet = false

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
                self.showPlanTrip = true
                self.mapDisplayMode = .planTrip
            }
            self.applyMapDisplayMode(.planTrip, duration: 0.8)
        }
    }

    func closePlanTrip() {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            showPlanTrip = false
            mapDisplayMode = .detail
        }

        applyMapDisplayMode(.detail, duration: 0.8)

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(180))
            if self.showDetail {
                self.showSheet = true
            }
        }
    }

    func openSavedTripInEditView(_ trip: Trip) {
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            showPlanTrip = false
            showSheet = false
            mapDisplayMode = .detail
        }

        applyMapDisplayMode(.detail, duration: 0.5)

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(160))
            self.selectedTripForEditing = trip
        }
    }

    func applyPlanTripDate(_ newDate: Date) {
        guard !isSyncingSharedDate else { return }

        let newHour = hourFraction(from: newDate)

        isSyncingSharedDate = true
        selectedDate = newDate
        hour = newHour
        parkDetailViewModel.selectedHour = min(18, max(6, Int(newHour.rounded())))
        planTripViewModel.selectedDate = newDate

        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.showDetail {
                await self.recalcAndGlow(for: newHour, date: newDate)
            }
            self.isSyncingSharedDate = false
        }
    }

    // MARK: - Date / hour sync
    func syncHourChange(_ newValue: Double) {
        guard !isSyncingSharedDate else { return }

        let updatedDate = dateByApplyingHour(newValue, to: selectedDate)
        let weatherHour = min(18, max(6, Int(newValue.rounded())))

        isSyncingSharedDate = true
        selectedDate = updatedDate
        parkDetailViewModel.selectedHour = weatherHour
        planTripViewModel.selectedDate = updatedDate

        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.showDetail {
                await self.recalcAndGlow(for: newValue, date: updatedDate)
            }
            self.isSyncingSharedDate = false
        }
    }

    func syncSelectedDateChange(_ newValue: Date) {
        guard !isSyncingSharedDate else { return }

        let newHour = hourFraction(from: newValue)

        isSyncingSharedDate = true
        hour = newHour
        parkDetailViewModel.selectedHour = min(18, max(6, Int(newHour.rounded())))
        planTripViewModel.selectedDate = newValue

        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.showDetail {
                await self.recalcAndGlow(for: newHour, date: newValue)
            }
            self.isSyncingSharedDate = false
        }
    }

    func dateByApplyingHour(_ sliderValue: Double, to date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current

        let h = Int(sliderValue)
        let m = Int(((sliderValue - Double(h)) * 60).rounded())

        return cal.date(
            bySettingHour: h,
            minute: m,
            second: 0,
            of: date
        ) ?? date
    }

    func hourFraction(from date: Date) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        let c = cal.dateComponents([.hour, .minute], from: date)
        return Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60.0
    }

    // MARK: - Camera mode
    func applyMapDisplayMode(_ mode: ShadeMapDisplayMode, duration: TimeInterval = 1.0) {
        mapDisplayMode = mode

        switch mode {
        case .main:
            scene.moveCamera(
                to: [3, 6, 3.5],
                target: [-0.5, -0.75, 0],
                duration: duration
            )
            scene.syncController(
                position: [3, 6, 3.5],
                target: [-0.5, -0.75, 0]
            )

        case .detail:
            scene.moveCamera(
                to: [1.2, 3.5, 4.5],
                target: [0, -1.0, 0],
                duration: duration
            )
            scene.syncController(
                position: [1.2, 3.5, 4.5],
                target: [0, -1.0, 0]
            )

        case .planTrip:
            scene.moveCamera(
                to: [-2.2, 2.5, 0.75],
                target: [0, -1.2, 0],
                duration: duration
            )
            scene.syncController(
                position: [-2.2, 2.5, 0.75],
                target: [0, -1.2, 0]
            )
        }
    }

    // MARK: - Shade calculation
    func recalcAndGlow(for sliderValue: Double, date: Date) async {
        let t0 = CFAbsoluteTimeGetCurrent()
        print("⏱[recalc] start")

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Jakarta")!

        let h = Int(sliderValue)
        let m = Int(((sliderValue - Double(h)) * 60).rounded())

        guard let start = cal.date(bySettingHour: h, minute: m, second: 0, of: date) else { return }
        let end = start.addingTimeInterval(15 * 60)

        scoreViewModel.startDate = start
        scoreViewModel.endDate = end
        scoreViewModel.stepMinutes = 15

        let tCalc = CFAbsoluteTimeGetCurrent()
        await scoreViewModel.calculate()
        print("⏱[recalc] calculate() took \(ms(tCalc))")

        let safe = Set(
            scoreViewModel.shadowResults
                .filter { $0.safetyStatus == .fullySafe || $0.safetyStatus == .recommended }
                .map { $0.spot.id }
        )

        let tGlow = CFAbsoluteTimeGetCurrent()
        scene.updateGlow(safeSpotIDs: safe)
        print("⏱[recalc] updateGlow took \(ms(tGlow)) | total \(ms(t0))")
    }
}
