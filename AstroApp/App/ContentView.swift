import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    // Her sekmenin kimliği. Sekmeden ayrılınca tazelenir; böylece geri
    // dönüldüğünde alt/detay sayfası değil sekmenin başlangıç sayfası açılır.
    @State private var homeResetID = UUID()
    @State private var astrologyResetID = UUID()
    @State private var cardResetID = UUID()
    @State private var settingsResetID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .id(homeResetID)
                .tag(0)
                .tabItem {
                    Label("Anasayfa", systemImage: "house.fill")
                }
            AstrologyTabView()
                .id(astrologyResetID)
                .tag(1)
                .tabItem {
                    Label("Astroloji", systemImage: "star.circle.fill")
                }
            CardReadingTabView()
                .id(cardResetID)
                .tag(2)
                .tabItem {
                    Label("Kart Falı", systemImage: "sparkles")
                }
            SettingsView()
                .id(settingsResetID)
                .tag(3)
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape")
                }
        }
        .tint(AstroTheme.accent)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { oldTab, _ in
            // Ayrılınan sekmeyi köküne sıfırla
            switch oldTab {
            case 0: homeResetID = UUID()
            case 1: astrologyResetID = UUID()
            case 2: cardResetID = UUID()
            case 3: settingsResetID = UUID()
            default: break
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .environment(EntitlementManager(store: StoreManager()))
}
