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

    var hasNatalChartOrTest: Bool {
        if Self.isAdmin { return true }
        #if DEBUG
        return true
        #else
        if Self.isTestFlight { return true }
        return hasNatalChart
        #endif
    }

    /// Admin cihaz mı kontrol et
    static let isAdmin: Bool = {
        let adminIDs: Set<String> = [
            "BF92A0DA-3782-415C-BF7F-4D9AC4AFD554"
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
