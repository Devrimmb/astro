import SwiftUI
import Network

struct AdGateView: View {
    @Environment(AppState.self) private var appState
    @State private var showSimulatedAd = false
    @State private var networkMonitor = NetworkMonitor()
    let title: String
    let description: String
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(AstroTheme.accent)

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(description)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            if networkMonitor.isConnected {
                Button {
                    showAd()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Reklam İzle ve Aç")
                    }
                    .glassButton()
                }
            } else {
                noInternetBanner
            }
        }
        .glassCard()
        .onChange(of: appState.adManager.rewardEarned) {
            if appState.adManager.rewardEarned {
                appState.adManager.resetReward()
                appState.gamification.earn(.watchAd)
                onUnlock()
            }
        }
        .fullScreenCover(isPresented: $showSimulatedAd) {
            SimulatedAdView {
                showSimulatedAd = false
                appState.adManager.rewardEarned = true
            } onDismiss: {
                showSimulatedAd = false
            }
        }
    }

    private var noInternetBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundStyle(AstroTheme.zorlayici)
            VStack(alignment: .leading, spacing: 2) {
                Text("İnternet Bağlantısı Yok")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Reklam izlemek için internet bağlantısı gerekli.")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AstroTheme.zorlayici.opacity(0.1), in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AstroTheme.zorlayici.opacity(0.3), lineWidth: 1)
        }
    }

    private func showAd() {
        if appState.adManager.rewardedAdAvailable {
            appState.adManager.showRewardedAd()
        } else {
            showSimulatedAd = true
        }
    }
}

// MARK: - Network Monitor

@Observable
final class NetworkMonitor {
    var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
