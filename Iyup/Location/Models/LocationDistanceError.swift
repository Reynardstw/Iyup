import Foundation

enum LocationDistanceError: LocalizedError {
    case authorizationDenied
    case locationUnavailable
    case requestReplaced

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Akses lokasi ditolak. Aktifkan izin lokasi Iyup di Pengaturan untuk menghitung jarak."
        case .locationUnavailable:
            return "Lokasi kamu belum bisa didapatkan. Coba lagi di tempat dengan sinyal lebih baik."
        case .requestReplaced:
            return "Permintaan lokasi sebelumnya dibatalkan karena ada permintaan baru."
        }
    }
}
