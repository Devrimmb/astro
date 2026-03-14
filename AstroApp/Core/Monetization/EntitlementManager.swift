import Foundation
import UIKit

enum AppFeature {
    case dailyHoroscope
    case tarot
    case moonPhase
    case elementAnalysis
    case detailedChart
    case compatibility
    case fullNatalChart
}

enum FeatureAccess: Sendable {
    case free
    case requiresPurchase(String)
    case locked
}

@Observable
final class EntitlementManager {
    private let store: StoreManager

    init(store: StoreManager) {
        self.store = store
    }

    func accessLevel(for feature: AppFeature) -> FeatureAccess {
        if Self.isAdmin { return .free }
        switch feature {
        case .dailyHoroscope, .tarot, .moonPhase, .elementAnalysis:
            return .free

        case .detailedChart, .compatibility:
            if store.isPurchased(StoreManager.natalChartID) ||
               store.isPurchased(StoreManager.allFeaturesID) {
                return .free
            }
            return .requiresPurchase(StoreManager.natalChartID)

        case .fullNatalChart:
            if store.isPurchased(StoreManager.natalChartID) ||
               store.isPurchased(StoreManager.allFeaturesID) {
                return .free
            }
            return .requiresPurchase(StoreManager.natalChartID)
        }
    }

    var hasFullAccess: Bool {
        Self.isAdmin || store.isPurchased(StoreManager.allFeaturesID)
    }

    var hasNatalChart: Bool {
        Self.isAdmin || store.isPurchased(StoreManager.natalChartID) || hasFullAccess
    }

    /// Harita hesaplama hakkı var mı? (admin, kredi veya allFeatures)
    var canCalculateChart: Bool {
        Self.isAdmin || store.chartCredits > 0 || store.isPurchased(StoreManager.allFeaturesID)
    }

    var hasNatalChartOrTest: Bool {
        if Self.isAdmin { return true }
        #if DEBUG
        return true
        #else
        if Self.isTestFlight { return true }
        return hasNatalChart
        #endif
    }

    /// Admin test modu — admin kullanıcı, normal kullanıcı gibi görebilir
    private static let adminTestModeKey = "admin_test_mode_enabled"

    static var adminTestMode: Bool {
        get { UserDefaults.standard.bool(forKey: adminTestModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: adminTestModeKey) }
    }

    /// Admin cihaz mı? (test modu açıksa false döner — normal kullanıcı gibi davranır)
    static var isAdmin: Bool {
        guard isAdminDevice else { return false }
        return !adminTestMode
    }

    /// Cihaz admin listesinde mi? (test modu'ndan bağımsız)
    static let isAdminDevice: Bool = {
        let adminIDs: Set<String> = [
            "BF92A0DA-3782-415C-BF7F-4D9AC4AFD554",
            "0F3534D6-A8AC-4093-89E5-C616A9DA32F5",
            "426A7520-78A7-4BAE-9DC3-489C1BE842B0"
        ]
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            return false
        }
        return adminIDs.contains(deviceID)
    }()

    /// TestFlight build'i mi kontrol et
    static let isTestFlight: Bool = {
        #if DEBUG
        return false
        #else
        return Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") != nil
        #endif
    }()
}
