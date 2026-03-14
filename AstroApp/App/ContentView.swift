import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Anasayfa", systemImage: "house.fill")
                }
            AstrologyTabView()
                .tabItem {
                    Label("Astroloji", systemImage: "star.circle.fill")
                }
            CardReadingTabView()
                .tabItem {
                    Label("Kart Falı", systemImage: "sparkles")
                }
            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape")
                }
        }
        .tint(AstroTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .environment(EntitlementManager(store: StoreManager()))
}
