import Foundation

enum AppFeature {
    case dailyHoroscope
    case tarot
    case moonPhase
    case elementAnalysis
    case detailedChart
    case compatibility
    case fullNatalChart
    case aiChat
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

        case .aiChat:
            if store.isPurchased(StoreManager.aiChatID) ||
               store.isPurchased(StoreManager.allFeaturesID) {
                return .free
            }
            return .requiresPurchase(StoreManager.aiChatID)
        }
    }

    var hasFullAccess: Bool {
        store.isPurchased(StoreManager.allFeaturesID)
    }

    var hasNatalChart: Bool {
        store.isPurchased(StoreManager.natalChartID) || hasFullAccess
    }

    var hasAIChat: Bool {
        #if DEBUG
        return true
        #else
        if Self.isTestFlight { return true }
        return store.isPurchased(StoreManager.aiChatID) || hasFullAccess
        #endif
    }

    var hasNatalChartOrTest: Bool {
        #if DEBUG
        return true
        #else
        if Self.isTestFlight { return true }
        return hasNatalChart
        #endif
    }

    /// TestFlight build'i mi kontrol et
    static let isTestFlight: Bool = {
        #if DEBUG
        return false
        #else
        return Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision") != nil
        #endif
    }()
}
