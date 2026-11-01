import Foundation
import UIKit

@Observable
final class EntitlementManager {
    private let store: StoreManager

    init(store: StoreManager) {
        self.store = store
    }

    /// Harita hesaplama hakkı var mı? (admin veya kredi)
    ///
    /// Satın alma yalnızca haritayı açar: her kredi bir kişinin haritasını hesaplar, okuma `ChartReadingStore`'a
    /// kaydedilir ve o kişinin harita yorumları (Hayat Döngüleri, Anı Haritası dahil) kalıcı olarak açık kalır.
    /// Diğer kilitli sayfalar (diğer burçlar, Ay/Yükselen, kart falları) satın almayla değil ödüllü reklamla açılır.
    var canCalculateChart: Bool {
        Self.isAdmin || store.chartCredits > 0
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
            "426A7520-78A7-4BAE-9DC3-489C1BE842B0",
            "A470F5C6-A9B1-4C09-9FA0-5FAE34154C4E",
            "41CB5742-7DB7-4B42-9940-F62C6E63E10A",
            "2510D36A-60B1-4634-A70A-EC6500DAEDBD"
        ]
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            return false
        }
        return adminIDs.contains(deviceID)
    }()
}
