import Foundation

struct IoTMQTTConfiguration: Sendable {
    let host: String
    let port: UInt16
    let username: String
    let password: String
    let topic: String
    let clientIDPrefix: String
    let keepAliveSeconds: UInt16

    static let hiveMQSensorData = IoTMQTTConfiguration(
        host: "41f67d4b12fc4889bacd88385da749e4.s1.eu.hivemq.cloud",
        port: 8883,
        username: "ESP-32",
        password: "Apple1234",
        topic: "sensor/data",
        clientIDPrefix: "Iyup-iOS",
        keepAliveSeconds: 30
    )
}
