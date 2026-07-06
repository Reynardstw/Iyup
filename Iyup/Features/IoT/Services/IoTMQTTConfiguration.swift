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
        host: "REDACTED_MQTT_HOST",
        port: 8883,
        username: "REDACTED_MQTT_USER",
        password: "REDACTED_MQTT_PASSWORD",
        topic: "sensor/data",
        clientIDPrefix: "Iyup-iOS",
        keepAliveSeconds: 30
    )
}
