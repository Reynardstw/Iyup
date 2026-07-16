import Foundation

enum ShadowSafetyStatus: String, CaseIterable, Sendable {
    case fullySafe = "Dim"
    case recommended = "Shady"
    case alternative = "Bright"
    case unsafe = "Very Bright"

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
