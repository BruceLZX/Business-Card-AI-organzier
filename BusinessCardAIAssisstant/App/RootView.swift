import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 900)) { context in
            ZStack {
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
                .preferredColorScheme(settings.appearance.effectiveColorScheme(for: context.date))
                .allowsHitTesting(!appState.isEnrichingGlobal)

                if let progress = appState.enrichmentProgress {
                    EnrichmentOverlay(progress: progress)
                }
            }
        }
    }
}

private struct EnrichmentOverlay: View {
    @EnvironmentObject private var settings: AppSettings
    let progress: EnrichmentProgressState

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text(stageText)
                    .font(.headline)
                    .foregroundStyle(.blue)
                ProgressView(value: progress.progress)
                    .progressViewStyle(.linear)
            }
            .padding(16)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var stageText: String {
        switch progress.stage {
        case .analyzing:
            return settings.text(.enrichStageAnalyzing)
        case .searching(let current, let total):
            return String(format: settings.text(.enrichStageSearching), current, total)
        case .merging:
            return settings.text(.enrichStageMerging)
        case .complete:
            return settings.text(.enrichStageComplete)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppSettings())
}
