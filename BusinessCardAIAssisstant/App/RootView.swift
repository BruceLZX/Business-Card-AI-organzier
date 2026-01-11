import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                YellowPagesView()
            }
            .tabItem {
                Label("Yellow Pages", systemImage: "list.bullet.rectangle")
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
