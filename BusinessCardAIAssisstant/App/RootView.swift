import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var appState: AppState
    @State private var selection: TabSelection = .create
    @State private var createResetID = UUID()
    @State private var directoryResetID = UUID()
    @State private var settingsResetID = UUID()

    private enum TabSelection {
        case create
        case directory
        case settings
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 900)) { context in
            TabView(selection: $selection) {
                NavigationStack {
                    HomeView()
                }
                .id(createResetID)
                .tabItem {
                    Label(settings.text(.captureTitle), systemImage: "camera.viewfinder")
                }
                .tag(TabSelection.create)

                NavigationStack {
                    DirectoryView()
                }
                .id(directoryResetID)
                .tabItem {
                    Label(settings.text(.directoryTitle), systemImage: "list.bullet.rectangle")
                }
                .tag(TabSelection.directory)

                NavigationStack {
                    SettingsView()
                }
                .id(settingsResetID)
                .tabItem {
                    Label(settings.text(.settingsTitle), systemImage: "gearshape")
                }
                .tag(TabSelection.settings)
            }
            .tint(settings.accentColor)
            .preferredColorScheme(settings.appearance.effectiveColorScheme(for: context.date))
            .allowsHitTesting(!appState.isEnrichingGlobal)
            .onChange(of: selection) { _, newValue in
                switch newValue {
                case .create:
                    createResetID = UUID()
                case .directory:
                    directoryResetID = UUID()
                case .settings:
                    settingsResetID = UUID()
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppSettings())
}
