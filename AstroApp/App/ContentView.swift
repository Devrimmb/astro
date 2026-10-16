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
        Group {
            if #available(iOS 18.0, *) {
                modernTabs
            } else {
                legacyTabs
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

    /// iOS 18+ `Tab` API'si; iOS 26'da sistem Liquid Glass çubuğu scroll'da küçülür.
    @available(iOS 18.0, *)
    private var modernTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Anasayfa", systemImage: "house.fill", value: 0) {
                HomeView().id(homeResetID)
            }
            Tab("Astroloji", systemImage: "star.circle.fill", value: 1) {
                AstrologyTabView().id(astrologyResetID)
            }
            Tab("Kart Falı", systemImage: "sparkles", value: 2) {
                CardReadingTabView().id(cardResetID)
            }
            Tab("Ayarlar", systemImage: "gearshape", value: 3) {
                SettingsView().id(settingsResetID)
            }
        }
        .modifier(TabBarMinimizeOnScroll())
    }

    private var legacyTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .id(homeResetID)
                .tag(0)
                .tabItem { Label("Anasayfa", systemImage: "house.fill") }
            AstrologyTabView()
                .id(astrologyResetID)
                .tag(1)
                .tabItem { Label("Astroloji", systemImage: "star.circle.fill") }
            CardReadingTabView()
                .id(cardResetID)
                .tag(2)
                .tabItem { Label("Kart Falı", systemImage: "sparkles") }
            SettingsView()
                .id(settingsResetID)
                .tag(3)
                .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
    }
}

/// iOS 26'da tab bar aşağı kaydırınca küçülür; altında etkisiz.
private struct TabBarMinimizeOnScroll: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(StoreManager())
        .environment(EntitlementManager(store: StoreManager()))
}
