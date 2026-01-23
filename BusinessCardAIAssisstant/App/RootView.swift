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
            .background(
                TabBarReselectObserver { index in
                    switch index {
                    case 0:
                        createResetID = UUID()
                    case 1:
                        directoryResetID = UUID()
                    case 2:
                        settingsResetID = UUID()
                    default:
                        break
                    }
                }
            )
        }
    }
}

#if canImport(UIKit)
private struct TabBarReselectObserver: UIViewControllerRepresentable {
    let onReselect: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReselect: onReselect)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let tabBarController = uiViewController.parent as? UITabBarController else { return }
        if tabBarController.delegate !== context.coordinator {
            tabBarController.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        private var lastIndex: Int?
        let onReselect: (Int) -> Void

        init(onReselect: @escaping (Int) -> Void) {
            self.onReselect = onReselect
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else { return }
            if lastIndex == index {
                onReselect(index)
            }
            lastIndex = index
        }
    }
}
#endif

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppSettings())
}
