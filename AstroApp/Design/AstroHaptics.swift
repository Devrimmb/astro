import CoreHaptics
import SwiftUI
import UIKit

/// Uygulamanın tek haptik katmanı. Her an bir isimle çağrılır (`selection`, `landing`, `cardEdge`…),
/// böylece aynı his her ekranda aynı kalır. Basit vuruşlar `UIFeedbackGenerator`; "nefes" ve skor finali
/// CoreHaptics desenleri (desteklemeyen cihazda generator yedeğine düşer).
/// Ayarlar → Titreşimler kapalıysa hiçbiri çalmaz.
enum AstroHaptics {
    private static let enabledKey = "hapticsEnabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Gecikmesiz ilk vuruş için; bir sahne başlamadan çağrılır
    static func prepare() {
        guard isEnabled else { return }
        selectionGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
    }

    // MARK: - Temel vuruşlar

    /// Seçim değişti: kişi, gezegen, çarkta kart geçişi
    static func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    /// Küçük bir şey yerine oturdu: gezegen inişi, açı çizimi, skor adımı
    static func tick(_ intensity: CGFloat = 0.55) {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: intensity)
    }

    /// Kullanıcı bir şeyi aldı/başlattı: kart seçme, karıştırma, Büyük Üçlü değişimi
    static func tap(_ intensity: CGFloat = 1) {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: intensity)
    }

    /// Hesap bitti, sonuç hazır
    static func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    // MARK: - Kart çevirme

    /// Kart kenarı (90°) geçerken kuru, kısa tık
    static func cardEdge() {
        guard isEnabled else { return }
        rigidGenerator.impactOccurred(intensity: 0.75)
    }

    /// Kartın yüzü yerine otururken yumuşak "yerleşme"
    static func cardSettle() {
        guard isEnabled else { return }
        softGenerator.impactOccurred(intensity: 0.6)
    }

    // MARK: - Desenler

    /// Açılış → anasayfa: yumuşak yükselip sönen "nefes"
    static func breath() {
        guard isEnabled else { return }
        let events = [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)
            ], relativeTime: 0, duration: 0.9)
        ]
        let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0, value: 0),
            .init(relativeTime: 0.5, value: 1),
            .init(relativeTime: 0.9, value: 0)
        ], relativeTime: 0)
        play(events: events, curves: [curve]) {
            softGenerator.impactOccurred(intensity: 0.5)
        }
    }

    /// Skor sayımının sonu: tek güçlü vuruş ve kısa bir yankı
    static func scoreFinale() {
        guard isEnabled else { return }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ], relativeTime: 0.02, duration: 0.22)
        ]
        let fade = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
            .init(relativeTime: 0.02, value: 1),
            .init(relativeTime: 0.24, value: 0)
        ], relativeTime: 0)
        play(events: events, curves: [fade]) {
            heavyGenerator.impactOccurred()
        }
    }

    // MARK: - CoreHaptics motoru

    private static let supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static var engine: CHHapticEngine?

    private static func play(events: [CHHapticEvent], curves: [CHHapticParameterCurve], fallback: () -> Void) {
        guard supportsCoreHaptics, let engine = makeEngine() else {
            fallback()
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            try engine.start()
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }

    private static func makeEngine() -> CHHapticEngine? {
        if let engine { return engine }
        guard let created = try? CHHapticEngine() else { return nil }
        // Boşta kalınca kendini kapatır; her desen öncesi `start()` motoru (sıfırlanmış olsa da) yeniden açar.
        // resetHandler bilinçli olarak yok: arka plan kuyruğunda çağrılır, MainActor varsayılanıyla çakışır.
        created.isAutoShutdownEnabled = true
        engine = created
        return created
    }
}

extension View {
    /// `sensoryFeedback`, Ayarlar → Titreşimler kapalıysa susar
    func astroFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        sensoryFeedback(feedback, trigger: trigger) { _, _ in AstroHaptics.isEnabled }
    }

    func astroFeedback<T: Equatable>(
        _ feedback: SensoryFeedback, trigger: T, condition: @escaping (T, T) -> Bool
    ) -> some View {
        sensoryFeedback(feedback, trigger: trigger) { old, new in AstroHaptics.isEnabled && condition(old, new) }
    }
}
