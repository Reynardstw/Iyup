import Foundation

struct ParkDetailInfo: Identifiable, Sendable {
    let id: String
    let name: String
    let city: String
    let entrance: String
    let hoursLabel: String
    let isOpen: Bool
    let openHoursDetail: String
    let address: String
    let distanceKm: Int
    let temperatureCelsius: Int
    let humidityPercent: Int
    let outfitHeadline: String
    let outfitEmojis: [String]
    let crowdLabel: String
    let recommendedShadeWindow: String
    let popularToday: [PopularSlot]
    let todayIndex: Int
}

struct PopularSlot: Identifiable, Sendable {
    let id = UUID()
    let hour: Int
    let level: Double
    let isNow: Bool
}

extension ParkDetailInfo {
    static let sample = ParkDetailInfo(
        id: "taman_bendera_pusaka",
        name: "Taman Bendera Pusaka",
        city: "South Jakarta",
        entrance: "FREE",
        hoursLabel: "Open",
        isOpen: true,
        openHoursDetail: "Open 24 Hours",
        address: "Jl. Barito I No.31, RT.3/RW.3, Kramat Pela, Kec. Kby. Baru, Kota Jakarta Selatan, Daerah Khusus Ibukota",
        distanceKm: 31,
        temperatureCelsius: 32,
        humidityPercent: 67,
        outfitHeadline: "Perfect weather for a loose t-shirt and airy sundress.",
        outfitEmojis: ["🕶️", "👒", "👟", "🩴"],
        crowdLabel: "Busy",
        recommendedShadeWindow: "08.00 - 10.00",
        popularToday: [
            PopularSlot(hour: 6, level: 0.15, isNow: false),
            PopularSlot(hour: 7, level: 0.28, isNow: false),
            PopularSlot(hour: 8, level: 0.42, isNow: false),
            PopularSlot(hour: 9, level: 0.55, isNow: false),
            PopularSlot(hour: 10, level: 0.48, isNow: false),
            PopularSlot(hour: 11, level: 0.40, isNow: false),
            PopularSlot(hour: 12, level: 0.52, isNow: false),
            PopularSlot(hour: 13, level: 0.60, isNow: false),
            PopularSlot(hour: 14, level: 0.72, isNow: false),
            PopularSlot(hour: 15, level: 0.95, isNow: true),
            PopularSlot(hour: 16, level: 0.68, isNow: false),
            PopularSlot(hour: 17, level: 0.50, isNow: false),
            PopularSlot(hour: 18, level: 0.30, isNow: false)
        ],
        todayIndex: 2
    )
}
