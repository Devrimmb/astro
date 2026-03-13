import SwiftUI
import GoogleMobileAds

@Observable
final class AdManager: NSObject {
    var isRewardedAdReady = false
    var rewardEarned = false

    private var rewardedAd: RewardedAd?

    // Google test ad unit ID — yayında gerçek ID ile değiştirilecek
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// Gerçek bir Google reklam yüklü mü?
    var rewardedAdAvailable: Bool {
        rewardedAd != nil
    }

    func configure() {
        // Preview ortamında GoogleMobileAds crash yapıyor — atla
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == nil else {
            isRewardedAdReady = true
            return
        }
        MobileAds.shared.start { _ in }
        #if DEBUG
        isRewardedAdReady = true
        #endif
    }

    /// TestFlight veya Debug ortamında test reklamı hazır mı?
    var canShowAd: Bool {
        #if DEBUG
        return true
        #else
        return isRewardedAdReady
        #endif
    }

    func loadRewardedAd() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == nil else { return }
        RewardedAd.load(with: rewardedAdUnitID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            if let ad {
                self.rewardedAd = ad
                self.isRewardedAdReady = true
            } else {
                #if DEBUG
                self.isRewardedAdReady = true
                #else
                self.isRewardedAdReady = false
                #endif
            }
        }
    }

    func showRewardedAd() {
        guard let ad = rewardedAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        ad.present(from: rootVC) { [weak self] in
            self?.rewardEarned = true
            self?.isRewardedAdReady = false
            self?.loadRewardedAd()
        }
    }

    func resetReward() {
        rewardEarned = false
    }
}
