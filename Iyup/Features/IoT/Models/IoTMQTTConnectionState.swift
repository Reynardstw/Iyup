import Foundation

enum IoTMQTTConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case subscribed
    case failed(String)

    var title: String {
        switch self {
        case .disconnected:
            return "Terputus"
        case .connecting:
            return "Menghubungkan"
        case .connected:
            return "Terhubung"
        case .subscribed:
            return "Menerima data"
        case .failed:
            return "Gagal"
        }
    }

    var isConnected: Bool {
        switch self {
        case .connected, .subscribed:
            return true
        case .disconnected, .connecting, .failed:
            return false
        }
    }
}
