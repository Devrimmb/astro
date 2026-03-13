import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Anasayfa", systemImage: "house.fill") {
                HomeView()
            }
            Tab("Astroloji", systemImage: "star.circle.fill") {
                AstrologyTabView()
            }
            Tab("Kart Falı", systemImage: "sparkles") {
                CardReadingTabView()
            }
            Tab("Ayarlar", systemImage: "gearshape") {
                SettingsView()
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
