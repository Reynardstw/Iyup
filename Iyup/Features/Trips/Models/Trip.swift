import Foundation

/// Satu rencana kunjungan yang disimpan user dari PlanTripView.
struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var parkName: String
    var city: String
    var address: String
    var latitude: Double
    var longitude: Double
    var date: Date                     // tanggal + jam yang dipilih
    var recommendedShadeWindow: String
    var alertOption: TripAlertOption
    var shadeConditionText: String
    var savedAt: Date

    init(
        id: UUID = UUID(),
        parkName: String,
        city: String = "",
        address: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        date: Date,
        recommendedShadeWindow: String,
        alertOption: TripAlertOption,
        shadeConditionText: String,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.parkName = parkName
        self.city = city
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.recommendedShadeWindow = recommendedShadeWindow
        self.alertOption = alertOption
        self.shadeConditionText = shadeConditionText
        self.savedAt = savedAt
    }
}
