import Foundation

struct ParkStaticInfo: Sendable {
    let placeID: String
    let name: String
    let city: String
    let entrance: String
    let hoursLabel: String
    let isOpen: Bool
    let openHoursDetail: String
    let address: String
}

enum ParkStaticDirectory {
    static let all: [String: ParkStaticInfo] = [
        "taman_bendera_pusaka": ParkStaticInfo(
            placeID: "taman_bendera_pusaka",
            name: "Taman Bendera Pusaka",
            city: "South Jakarta",
            entrance: "FREE",
            hoursLabel: "Open",
            isOpen: true,
            openHoursDetail: "Open 24 Hours",
            address: "Jl. Barito I No.31, RT.3/RW.3, Kramat Pela, Kec. Kby. Baru, Kota Jakarta Selatan, Daerah Khusus Ibukota"
        )
    ]

    static func info(for placeID: String) -> ParkStaticInfo {
        all[placeID] ?? all["taman_bendera_pusaka"]!
    }
}
