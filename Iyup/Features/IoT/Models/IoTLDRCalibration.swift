import Foundation

struct IoTLDRCalibration: Sendable {
    let vin: Double
    let fixedResistanceOhm: Double
    let adcMaxValue: Double
    let luxScale: Double
    let luxExponent: Double

    static let esp32LDR100Ohm = IoTLDRCalibration(
        vin: 3.3,
        fixedResistanceOhm: 100.0,
        adcMaxValue: 4095.0,
        luxScale: 500_000.0,
        luxExponent: 1.0 / 1.25
    )

    func reading(from adcValue: Int) -> IoTLDRReading? {
        guard adcValue > 0 else { return nil }

        let voltage = (Double(adcValue) / adcMaxValue) * vin
        guard voltage > 0, voltage < vin else { return nil }

        let resistanceOhm = fixedResistanceOhm * (vin - voltage) / voltage
        guard resistanceOhm > 0, resistanceOhm.isFinite else { return nil }

        let estimatedLux = pow(luxScale / resistanceOhm, luxExponent)
        guard estimatedLux.isFinite else { return nil }

        return IoTLDRReading(
            adcValue: adcValue,
            voltage: voltage,
            resistanceOhm: resistanceOhm,
            estimatedLux: estimatedLux
        )
    }
}

struct IoTLDRReading: Sendable {
    let adcValue: Int
    let voltage: Double
    let resistanceOhm: Double
    let estimatedLux: Double
}
