import Foundation
import Network

class IoTMQTTClient {
    var onStateChange: ((IoTMQTTConnectionState) -> Void)?
    var onSnapshot: ((IoTSensorSnapshot) -> Void)?
    var onRawMessage: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let configuration: IoTMQTTConfiguration
    private let queue = DispatchQueue(label: "iyup.iot.mqtt.client")
    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private var packetIdentifier: UInt16 = 1
    private var pingTimer: DispatchSourceTimer?
    private let decoder = JSONDecoder()

    init(configuration: IoTMQTTConfiguration) {
        self.configuration = configuration
    }

    func connect() {
        disconnect()
        emitState(.connecting)

        let endpointHost = NWEndpoint.Host(configuration.host)
        let endpointPort = NWEndpoint.Port(rawValue: configuration.port) ?? 8883
        let parameters = NWParameters.tls
        parameters.allowLocalEndpointReuse = true

        let connection = NWConnection(
            host: endpointHost,
            port: endpointPort,
            using: parameters
        )

        self.connection = connection

        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }

        connection.start(queue: queue)
    }

    func disconnect() {
        stopPingTimer()
        connection?.cancel()
        connection = nil
        receiveBuffer.removeAll()
        emitState(.disconnected)
    }

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            sendConnectPacket()
            startReceiveLoop()
            startPingTimer()
        case .failed(let error):
            emitFailure(error.localizedDescription)
        case .cancelled:
            stopPingTimer()
            emitState(.disconnected)
        case .waiting(let error):
            emitFailure(error.localizedDescription)
        case .setup, .preparing:
            break
        @unknown default:
            break
        }
    }

    private func startReceiveLoop() {
        connection?.receive(
            minimumIncompleteLength: 1,
            maximumLength: 4096
        ) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                self.receiveBuffer.append(data)
                self.processReceiveBuffer()
            }

            if let error {
                self.emitFailure(error.localizedDescription)
                return
            }

            if isComplete {
                self.emitState(.disconnected)
                return
            }

            self.startReceiveLoop()
        }
    }

    private func processReceiveBuffer() {
        while let packet = extractPacket() {
            handlePacket(packet)
        }
    }

    private func extractPacket() -> MQTTIncomingPacket? {
        guard receiveBuffer.count >= 2 else { return nil }

        let fixedHeader = receiveBuffer[receiveBuffer.startIndex]
        var multiplier = 1
        var remainingLength = 0
        var index = receiveBuffer.index(after: receiveBuffer.startIndex)
        var encodedByteCount = 0

        while true {
            guard index < receiveBuffer.endIndex else { return nil }

            let byte = Int(receiveBuffer[index])
            remainingLength += (byte & 127) * multiplier
            multiplier *= 128
            encodedByteCount += 1
            index = receiveBuffer.index(after: index)

            if byte & 128 == 0 { break }
            if encodedByteCount >= 4 {
                emitFailure("Remaining length MQTT tidak valid")
                receiveBuffer.removeAll()
                return nil
            }
        }

        let headerLength = 1 + encodedByteCount
        let totalLength = headerLength + remainingLength
        guard receiveBuffer.count >= totalLength else { return nil }

        let payloadStart = receiveBuffer.index(receiveBuffer.startIndex, offsetBy: headerLength)
        let payloadEnd = receiveBuffer.index(receiveBuffer.startIndex, offsetBy: totalLength)
        let payload = Data(receiveBuffer[payloadStart..<payloadEnd])
        receiveBuffer.removeSubrange(receiveBuffer.startIndex..<payloadEnd)

        return MQTTIncomingPacket(fixedHeader: fixedHeader, payload: payload)
    }

    private func handlePacket(_ packet: MQTTIncomingPacket) {
        let packetType = packet.fixedHeader & 0xF0

        switch packetType {
        case 0x20:
            handleConnAck(packet.payload)
        case 0x90:
            emitState(.subscribed)
        case 0x30:
            handlePublish(packet)
        case 0xD0:
            break
        default:
            break
        }
    }

    private func handleConnAck(_ payload: Data) {
        guard payload.count >= 2 else {
            emitFailure("CONNACK MQTT tidak valid")
            return
        }

        let returnCode = payload[payload.index(payload.startIndex, offsetBy: 1)]
        guard returnCode == 0 else {
            emitFailure("Broker menolak koneksi MQTT dengan kode \(returnCode)")
            return
        }

        emitState(.connected)
        sendSubscribePacket(topic: configuration.topic)
    }

    private func handlePublish(_ packet: MQTTIncomingPacket) {
        let qos = (packet.fixedHeader & 0x06) >> 1
        var index = packet.payload.startIndex

        guard let topic = readMQTTString(from: packet.payload, index: &index) else {
            emitFailure("Topic PUBLISH tidak valid")
            return
        }

        if qos > 0 {
            guard packet.payload.distance(from: index, to: packet.payload.endIndex) >= 2 else { return }
            index = packet.payload.index(index, offsetBy: 2)
        }

        let payloadData = Data(packet.payload[index..<packet.payload.endIndex])
        guard let payloadText = String(data: payloadData, encoding: .utf8) else {
            emitFailure("Payload MQTT bukan UTF-8")
            return
        }

        onRawMessage?("[\(topic)] \(payloadText)")

        do {
            let snapshot = try decoder.decode(IoTSensorSnapshot.self, from: payloadData)
            onSnapshot?(snapshot)
        } catch {
            emitFailure("Gagal parse JSON sensor: \(error.localizedDescription)")
        }
    }

    private func sendConnectPacket() {
        var variableHeader = Data()
        variableHeader.appendMQTTString("MQTT")
        variableHeader.append(0x04)
        variableHeader.append(0xC2)
        variableHeader.appendUInt16(configuration.keepAliveSeconds)

        var payload = Data()
        payload.appendMQTTString(makeClientID())
        payload.appendMQTTString(configuration.username)
        payload.appendMQTTString(configuration.password)

        sendPacket(type: 0x10, payload: variableHeader + payload)
    }

    private func sendSubscribePacket(topic: String) {
        var payload = Data()
        payload.appendUInt16(nextPacketIdentifier())
        payload.appendMQTTString(topic)
        payload.append(0x00)
        sendPacket(type: 0x82, payload: payload)
    }

    private func sendPingPacket() {
        sendPacket(type: 0xC0, payload: Data())
    }

    private func sendPacket(type: UInt8, payload: Data) {
        var packet = Data([type])
        packet.appendEncodedRemainingLength(payload.count)
        packet.append(payload)

        connection?.send(content: packet, completion: .contentProcessed { [weak self] error in
            if let error {
                self?.emitFailure(error.localizedDescription)
            }
        })
    }

    private func makeClientID() -> String {
        let suffix = UUID().uuidString.prefix(8)
        return "\(configuration.clientIDPrefix)-\(suffix)"
    }

    private func nextPacketIdentifier() -> UInt16 {
        let value = packetIdentifier
        packetIdentifier = packetIdentifier == UInt16.max ? 1 : packetIdentifier + 1
        return value
    }

    private func startPingTimer() {
        stopPingTimer()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + .seconds(Int(configuration.keepAliveSeconds / 2)),
            repeating: .seconds(Int(configuration.keepAliveSeconds / 2))
        )
        timer.setEventHandler { [weak self] in
            self?.sendPingPacket()
        }
        timer.resume()
        pingTimer = timer
    }

    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    private func readMQTTString(from data: Data, index: inout Data.Index) -> String? {
        guard data.distance(from: index, to: data.endIndex) >= 2 else { return nil }

        let lengthHigh = UInt16(data[index])
        index = data.index(after: index)
        let lengthLow = UInt16(data[index])
        index = data.index(after: index)
        let length = Int((lengthHigh << 8) | lengthLow)

        guard data.distance(from: index, to: data.endIndex) >= length else { return nil }

        let endIndex = data.index(index, offsetBy: length)
        let stringData = Data(data[index..<endIndex])
        index = endIndex

        return String(data: stringData, encoding: .utf8)
    }

    private func emitState(_ state: IoTMQTTConnectionState) {
        onStateChange?(state)
    }

    private func emitFailure(_ message: String) {
        onError?(message)
        onStateChange?(.failed(message))
    }
}

private struct MQTTIncomingPacket {
    let fixedHeader: UInt8
    let payload: Data
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func appendMQTTString(_ string: String) {
        let data = Data(string.utf8)
        appendUInt16(UInt16(data.count))
        append(data)
    }

    mutating func appendEncodedRemainingLength(_ length: Int) {
        var value = length

        repeat {
            var encodedByte = UInt8(value % 128)
            value /= 128

            if value > 0 {
                encodedByte |= 128
            }

            append(encodedByte)
        } while value > 0
    }
}
