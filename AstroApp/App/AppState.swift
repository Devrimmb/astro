import SwiftUI
import WidgetKit

@Observable
class AppState {
    var currentChart: BirthChart?
    let ephemeris: EphemerisManager
    let interpretation: InterpretationEngine
    let store: StoreManager
    let entitlements: EntitlementManager
    let birthDataStore: BirthDataStore
    let adManager: AdManager

    init(
        ephemeris: EphemerisManager = EphemerisManager(),
        interpretation: InterpretationEngine = InterpretationEngine()
    ) {
        self.ephemeris = ephemeris
        self.interpretation = interpretation
        let store = StoreManager()
        self.store = store
        self.entitlements = EntitlementManager(store: store)
        self.birthDataStore = BirthDataStore()
        self.adManager = AdManager()
        self.adManager.configure()
        self.adManager.loadRewardedAd()
    }

    /// Kaydedilmiş doğum verisinden haritayı yeniden hesapla
    func restoreSavedChart() async {
        guard let data = birthDataStore.savedData else { return }
        let chart = await ephemeris.calculateBirthChart(
            date: data.birthDate,
            latitude: data.latitude,
            longitude: data.longitude,
            timeZone: TimeZone(identifier: "Europe/Istanbul")!
        )
        currentChart = chart
        syncWidgetData()
    }

    /// Widget ile veri paylas
    func syncWidgetData() {
        let data = birthDataStore.savedData
        let signRaw: String
        if let chart = currentChart, let sun = chart.sunSign {
            signRaw = sun.name
        } else if let birthDate = data?.birthDate {
            signRaw = ZodiacSign.from(birthDate: birthDate).name
        } else {
            return
        }
        let name = data?.name ?? ""
        let lat = data?.latitude ?? 41.0082
        let lon = data?.longitude ?? 28.9784
        SharedDefaults.saveForWidget(signRawValue: signRaw, name: name, latitude: lat, longitude: lon, birthDate: data?.birthDate)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
