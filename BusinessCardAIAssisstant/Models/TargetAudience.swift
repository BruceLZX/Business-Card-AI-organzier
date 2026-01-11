import Foundation

enum TargetAudience: String, CaseIterable, Identifiable, Codable {
    case b2b = "B2B"
    case b2c = "B2C"

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch (self, language) {
        case (.b2b, .english):
            return "B2B"
        case (.b2c, .english):
            return "B2C"
        case (.b2b, .chinese):
            return "To B"
        case (.b2c, .chinese):
            return "To C"
        }
    }
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

    func label(language: AppLanguage) -> String {
        switch (self, language) {
        case (.any, .english):
            return "Any"
        case (.b2b, .english):
            return "B2B"
        case (.b2c, .english):
            return "B2C"
        case (.any, .chinese):
            return "不限"
        case (.b2b, .chinese):
            return "To B"
        case (.b2c, .chinese):
            return "To C"
        }
    }
}
