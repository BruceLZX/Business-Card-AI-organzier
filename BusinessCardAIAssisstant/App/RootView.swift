import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(settings.text(.captureTitle), systemImage: "camera.viewfinder")
            }

            NavigationStack {
                DirectoryView()
            }
            .tabItem {
                Label(settings.text(.directoryTitle), systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(settings.text(.settingsTitle), systemImage: "gearshape")
            }
        }
        .tint(settings.accentColor)
        .preferredColorScheme(settings.appearance.colorScheme)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppSettings())
}
