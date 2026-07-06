import Foundation

struct IoTSensorSnapshot: Identifiable, Decodable, Sendable {
    let id = UUID()
    let peopleCount: Int
    let temperatureCelsius: Double
    let humidityPercent: Double
    let lightADC: Int
    let receivedAt: Date

    enum CodingKeys: String, CodingKey {
        case peopleCount = "Orang"
        case temperatureCelsius = "Suhu"
        case humidityPercent = "Kelembapan"
        case lightADC = "Cahaya"
    }

    init(
        peopleCount: Int,
        temperatureCelsius: Double,
        humidityPercent: Double,
        lightADC: Int,
        receivedAt: Date = Date()
    ) {
        self.peopleCount = peopleCount
        self.temperatureCelsius = temperatureCelsius
        self.humidityPercent = humidityPercent
        self.lightADC = lightADC
        self.receivedAt = receivedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peopleCount = try container.decode(Int.self, forKey: .peopleCount)
        temperatureCelsius = try container.decode(Double.self, forKey: .temperatureCelsius)
        humidityPercent = try container.decode(Double.self, forKey: .humidityPercent)
        lightADC = try container.decode(Int.self, forKey: .lightADC)
        receivedAt = Date()
    }

    var ldrReading: IoTLDRReading? {
        IoTLDRCalibration.esp32LDR100Ohm.reading(from: lightADC)
    }

    var estimatedLux: Double? {
        ldrReading?.estimatedLux
    }
}
