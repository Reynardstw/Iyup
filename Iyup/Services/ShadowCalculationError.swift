import Foundation

enum ShadowCalculationError: LocalizedError {
    case invalidDateInterval
    case invalidStepMinutes
    case emptySpots

    var errorDescription: String? {
        switch self {
        case .invalidDateInterval:
            return "End time harus lebih besar dari start time."
        case .invalidStepMinutes:
            return "Step interval harus lebih besar dari 0 menit."
        case .emptySpots:
            return "Daftar spot masih kosong."
        }
    }
}
