import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case chinese = "中文"

    var id: String { rawValue }

    var languageCode: String {
        switch self {
        case .english:
            return "en"
        case .chinese:
            return "zh"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    func label(for language: AppLanguage) -> String {
        switch (self, language) {
        case (.system, .english): return "System"
        case (.system, .chinese): return "跟随系统"
        case (.light, .english): return "Light"
        case (.light, .chinese): return "浅色"
        case (.dark, .english): return "Dark"
        case (.dark, .chinese): return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func effectiveColorScheme(for date: Date) -> ColorScheme? {
        switch self {
        case .system:
            let hour = Calendar.current.component(.hour, from: date)
            return (hour >= 18 || hour < 6) ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app.language") }
    }
    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "app.appearance") }
    }
    @Published var enableHaptics: Bool {
        didSet { UserDefaults.standard.set(enableHaptics, forKey: "app.haptics") }
    }
    @Published var autoSaveCaptures: Bool {
        didSet { UserDefaults.standard.set(autoSaveCaptures, forKey: "app.autoSaveCaptures") }
    }
    @Published var keepOriginalPhotos: Bool {
        didSet { UserDefaults.standard.set(keepOriginalPhotos, forKey: "app.keepOriginalPhotos") }
    }
    @Published var enableEnrichment: Bool {
        didSet { UserDefaults.standard.set(enableEnrichment, forKey: "app.enableEnrichment") }
    }

    var accentColor: Color {
        Color.accentColor
    }

    init() {
        let storedLanguage = UserDefaults.standard.string(forKey: "app.language")
        language = AppLanguage(rawValue: storedLanguage ?? "") ?? .english

        let storedAppearance = UserDefaults.standard.string(forKey: "app.appearance")
        appearance = AppAppearance(rawValue: storedAppearance ?? "") ?? .system

        enableHaptics = UserDefaults.standard.object(forKey: "app.haptics") as? Bool ?? true
        autoSaveCaptures = UserDefaults.standard.object(forKey: "app.autoSaveCaptures") as? Bool ?? true
        keepOriginalPhotos = UserDefaults.standard.object(forKey: "app.keepOriginalPhotos") as? Bool ?? true
        enableEnrichment = UserDefaults.standard.object(forKey: "app.enableEnrichment") as? Bool ?? true
    }

    func text(_ key: AppStringKey) -> String {
        AppStrings.text(key, language: language)
    }
}
