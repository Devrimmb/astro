import Foundation

enum MoonPhaseName: Sendable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    var name: String {
        switch self {
        case .newMoon: "Yeni Ay"
        case .waxingCrescent: "Hilal (Büyüyen)"
        case .firstQuarter: "İlk Dördün"
        case .waxingGibbous: "Şişkin Ay (Büyüyen)"
        case .fullMoon: "Dolunay"
        case .waningGibbous: "Şişkin Ay (Küçülen)"
        case .lastQuarter: "Son Dördün"
        case .waningCrescent: "Hilal (Küçülen)"
        }
    }

    var emoji: String {
        switch self {
        case .newMoon: "🌑"
        case .waxingCrescent: "🌒"
        case .firstQuarter: "🌓"
        case .waxingGibbous: "🌔"
        case .fullMoon: "🌕"
        case .waningGibbous: "🌖"
        case .lastQuarter: "🌗"
        case .waningCrescent: "🌘"
        }
    }

    var description: String {
        switch self {
        case .newMoon:
            "Yeni başlangıçlar ve niyet belirleme zamanı. İçe dönük enerji güçlü. Yeni projeler başlatmak için ideal."
        case .waxingCrescent:
            "Niyetleriniz filizleniyor. İlk adımları atma ve plan yapma zamanı. Motivasyonunuz yükseliyor."
        case .firstQuarter:
            "Eylem zamanı. Engellerle karşılaşabilirsiniz ama kararlı kalmak önemli. Karar verme enerjisi güçlü."
        case .waxingGibbous:
            "İnce ayar yapma zamanı. Planlarınızı gözden geçirin ve detayları düzeltin. Sabır meyvesini verecek."
        case .fullMoon:
            "Duygular yoğun, sezgiler güçlü. Sonuçları görme ve kutlama zamanı. Bırakmanız gerekenleri bırakın."
        case .waningGibbous:
            "Şükran ve paylaşım zamanı. Öğrendiklerinizi başkalarıyla paylaşın. Minnettarlık enerjisi yüksek."
        case .lastQuarter:
            "Arınma ve bırakma zamanı. Artık işe yaramayan alışkanlıklardan vazgeçin. İç temizlik yapın."
        case .waningCrescent:
            "Dinlenme ve hazırlanma zamanı. Enerjinizi koruyun, kendinize bakın. Yeni döngü yaklaşıyor."
        }
    }

    var energies: [String] {
        switch self {
        case .newMoon:
            ["Niyet belirleme", "Meditasyon", "Yeni başlangıçlar", "İçe dönüş"]
        case .waxingCrescent:
            ["Plan yapma", "İlk adımlar", "Umut", "Büyüme"]
        case .firstQuarter:
            ["Eylem", "Kararlılık", "Zorlukları aşma", "Cesaret"]
        case .waxingGibbous:
            ["İnce ayar", "Detaylara dikkat", "Sabır", "Geliştirme"]
        case .fullMoon:
            ["Kutlama", "Sezgi", "Duygusal farkındalık", "Bırakma"]
        case .waningGibbous:
            ["Şükran", "Paylaşım", "Öğretme", "Minnettarlık"]
        case .lastQuarter:
            ["Arınma", "Vazgeçme", "İç temizlik", "Basitleştirme"]
        case .waningCrescent:
            ["Dinlenme", "Hazırlanma", "Rüyalar", "Sezgisel mesajlar"]
        }
    }
}

struct MoonPhaseInfo: Sendable {
    let phase: MoonPhaseName
    let illumination: Double
    let date: Date
    let moonSign: ZodiacSign?

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: date)
    }
}

enum MoonPhaseCalculator {

    /// Basit ay evresi hesaplama — sinodik döngü bazlı
    static func currentPhase() -> MoonPhaseInfo {
        phaseInfo(for: .now)
    }

    static func upcomingPhases(count: Int) -> [MoonPhaseInfo] {
        var results: [MoonPhaseInfo] = []
        var date = Date.now
        var lastPhase: MoonPhaseName?

        // Günlük ilerleyerek farklı evreleri topla
        while results.count < count {
            date = date.addingTimeInterval(86400) // +1 gün
            let info = phaseInfo(for: date)
            if info.phase != lastPhase {
                results.append(info)
                lastPhase = info.phase
            }
        }
        return results
    }

    static func phaseInfo(for date: Date) -> MoonPhaseInfo {
        let age = moonAge(for: date)
        let phase = phaseName(from: age)
        let illumination = illuminationFraction(from: age)
        let moonSign = approximateMoonSign(for: date)

        return MoonPhaseInfo(
            phase: phase,
            illumination: illumination,
            date: date,
            moonSign: moonSign
        )
    }

    // MARK: - Sinodik Döngü Hesaplama

    /// Bilinen yeni ay referans noktası: 6 Ocak 2000 18:14 UTC
    private static let knownNewMoon: TimeInterval = 947182440 // 2000-01-06 18:14 UTC
    private static let synodicMonth: TimeInterval = 29.53058770576 * 86400

    /// Ayın "yaşı" — sinodik döngüdeki gün
    private static func moonAge(for date: Date) -> Double {
        let elapsed = date.timeIntervalSince1970 - knownNewMoon
        let cycles = elapsed / synodicMonth
        return (cycles - Foundation.floor(cycles)) * 29.53058770576
    }

    private static func phaseName(from age: Double) -> MoonPhaseName {
        switch age {
        case 0..<1.85:     .newMoon
        case 1.85..<7.38:  .waxingCrescent
        case 7.38..<9.23:  .firstQuarter
        case 9.23..<14.77: .waxingGibbous
        case 14.77..<16.61: .fullMoon
        case 16.61..<22.15: .waningGibbous
        case 22.15..<24.0:  .lastQuarter
        default:            .waningCrescent
        }
    }

    private static func illuminationFraction(from age: Double) -> Double {
        let angle = age / 29.53058770576 * 2 * .pi
        return (1 - Foundation.cos(angle)) / 2
    }

    /// Yaklaşık Ay burcu — Ay ~27.3 günde 360° döner (sidereal)
    private static func approximateMoonSign(for date: Date) -> ZodiacSign {
        let siderealMonth: TimeInterval = 27.321661 * 86400
        let elapsed = date.timeIntervalSince1970 - knownNewMoon
        let siderealCycles = elapsed / siderealMonth
        let fraction = siderealCycles - Foundation.floor(siderealCycles)
        // Referans noktasında Ay ~Oğlak civarı (Güneş Oğlak'ta yeni ay)
        let longitude = Foundation.fmod(280.0 + fraction * 360.0, 360.0)
        return ZodiacSign.from(longitude: longitude)
    }
}
