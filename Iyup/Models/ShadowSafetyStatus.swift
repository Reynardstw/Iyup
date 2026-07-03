import Foundation

enum ShadowSafetyStatus: String, CaseIterable, Sendable {
    case fullySafe = "Aman penuh"
    case recommended = "Direkomendasikan"
    case alternative = "Alternatif"
    case unsafe = "Tidak aman"

    var rankPriority: Int {
        switch self {
        case .fullySafe:
            return 0
        case .recommended:
            return 1
        case .alternative:
            return 2
        case .unsafe:
            return 3
        }
    }
}
