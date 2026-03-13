import SwiftUI

@main
struct AstroAppApp: App {
    @State private var appState = AppState()
    @State private var showOnboarding = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)
                    .environment(appState.store)
                    .environment(appState.entitlements)
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView {
                            showOnboarding = false
                        }
                        .environment(appState)
                        .environment(appState.store)
                        .environment(appState.entitlements)
                    }
                    .task {
                        if !appState.birthDataStore.hasCompletedOnboarding {
                            showOnboarding = true
                        } else {
                            await appState.restoreSavedChart()
                        }
                    }

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.identity)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
