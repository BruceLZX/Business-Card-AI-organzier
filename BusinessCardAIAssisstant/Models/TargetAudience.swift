import Foundation

enum TargetAudience: String, CaseIterable, Identifiable {
    case b2b = "B2B"
    case b2c = "B2C"

    var id: String { rawValue }
}

enum TargetAudienceFilter: String, CaseIterable, Identifiable {
    case any = "Any"
    case b2b = "B2B"
    case b2c = "B2C"

    var id: String { rawValue }

    var asAudience: TargetAudience? {
        switch self {
        case .any:
            return nil
        case .b2b:
            return .b2b
        case .b2c:
            return .b2c
        }
    }
}
