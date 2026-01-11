import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section(settings.text(.appearance)) {
                Picker(settings.text(.appearanceMode), selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.label(for: settings.language)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(settings.text(.language)) {
                Picker(settings.text(.language), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.rawValue).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(settings.text(.preferences)) {
                Toggle(settings.text(.enableHaptics), isOn: $settings.enableHaptics)
                Toggle(settings.text(.autoSaveCaptures), isOn: $settings.autoSaveCaptures)
                Toggle(settings.text(.keepOriginalPhotos), isOn: $settings.keepOriginalPhotos)
                Toggle(settings.text(.enableEnrichment), isOn: $settings.enableEnrichment)
            }
        }
        .navigationTitle(settings.text(.settingsTitle))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
    }
}
