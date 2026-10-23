import SwiftUI

enum AstroTheme {
    // Arka plan — derin koyu, hafif mavi ton
    static let background = Color(red: 0.04, green: 0.05, blue: 0.12)
    static let backgroundMid = Color(red: 0.07, green: 0.06, blue: 0.18)
    static let surface = Color.white.opacity(0.06)
    static let surfaceElevated = Color.white.opacity(0.10)

    // Vurgu
    static let accent = Color(red: 0.56, green: 0.44, blue: 1.0)   // Lavanta
    static let accentSecondary = Color(red: 0.35, green: 0.78, blue: 0.98) // Açık mavi

    // Metin
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.3)

    // Element renkleri — pastel, modern
    static let fire = Color(red: 1.0, green: 0.45, blue: 0.42)
    static let earth = Color(red: 0.42, green: 0.82, blue: 0.52)
    static let air = Color(red: 1.0, green: 0.85, blue: 0.35)
    static let water = Color(red: 0.40, green: 0.68, blue: 1.0)

    // Açı renkleri
    static let harmonik = Color(red: 0.30, green: 0.85, blue: 0.65)
    static let zorlayici = Color(red: 1.0, green: 0.40, blue: 0.45)
    static let notr = Color(red: 0.55, green: 0.55, blue: 1.0)

    // Gradient'ler
    static let backgroundGradient = LinearGradient(
        colors: [background, backgroundMid, background],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Kart yüzlerindeki altın vurgu — deste çarkı, tarot/katina ön yüz çerçevesi
    static let gold = Color(red: 0.91, green: 0.78, blue: 0.49)

    // Cam katmanı
    static let cardBorder = Color.white.opacity(0.08)
    /// Kartın üst kenarındaki 1px parlama — camın ışığı yakaladığı hissini verir
    static let cardSpecular = Color.white.opacity(0.22)

    // MARK: - Gezegen paleti

    /// Koyu zemin için ayarlanmış gezegen renkleri. Çark, bi-wheel, gezegen saatleri
    /// ve satır bileşenleri hep buradan okur; sistem renkleri (.orange, .brown…) kullanılmaz.
    static func planet(_ planet: AstroApp.Planet) -> Color {
        switch planet {
        case .sun:           Color(red: 1.0, green: 0.71, blue: 0.28)   // #FFB547
        case .moon:          Color(red: 0.91, green: 0.93, blue: 1.0)   // #E8ECFF
        case .mercury:       Color(red: 0.35, green: 0.85, blue: 0.90)  // #5AD8E6
        case .venus:         Color(red: 1.0, green: 0.54, blue: 0.72)   // #FF8AB8
        case .mars:          Color(red: 1.0, green: 0.37, blue: 0.34)   // #FF5F57
        case .jupiter:       Color(red: 0.73, green: 0.55, blue: 1.0)   // #B98CFF
        case .saturn:        Color(red: 0.79, green: 0.64, blue: 0.49)  // #C9A27E
        case .uranus:        Color(red: 0.37, green: 0.92, blue: 0.83)  // #5EEAD4
        case .neptune:       Color(red: 0.48, green: 0.55, blue: 1.0)   // #7B8CFF
        case .pluto:         Color(red: 0.61, green: 0.64, blue: 0.69)  // #9CA3AF
        case .northNode:     Color(red: 0.60, green: 0.90, blue: 0.75)
        case .chiron:        Color(red: 0.95, green: 0.85, blue: 0.45)
        case .lilith:        Color(red: 0.62, green: 0.40, blue: 0.70)
        case .partOfFortune: Color(red: 0.55, green: 0.88, blue: 0.55)
        case .ceres:         Color(red: 0.80, green: 0.62, blue: 0.42)
        case .pallas:        Color(red: 0.60, green: 0.76, blue: 0.95)
        case .juno:          Color(red: 0.90, green: 0.55, blue: 0.72)
        case .vesta:         Color(red: 1.0, green: 0.62, blue: 0.36)
        }
    }

    /// Harita noktası → renk: gezegen kendi paleti, AC harmonik, MC ikincil metin
    static func point(_ point: ChartPoint) -> Color {
        switch point {
        case .planet(let p): planet(p)
        case .ascendant:     harmonik
        case .midheaven:     textSecondary
        }
    }

    // MARK: - Anlam renkleri

    /// Açı / rehberlik tonu → renk. Tek kaynak; ekranlar kendi switch'ini yazmaz.
    static func tone(_ tone: DailyCosmicCoach.Tone) -> Color {
        switch tone {
        case .harmonik:  harmonik
        case .zorlayici: zorlayici
        case .notr:      notr
        }
    }

    /// Açı doğası → renk (çark çizgileri, açı matrisi, orb rozetleri)
    static func nature(_ nature: AspectType.Nature) -> Color {
        switch nature {
        case .harmonik:  harmonik
        case .zorlayici: zorlayici
        case .notr:      notr
        }
    }

    static func element(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  fire
        case .earth: earth
        case .air:   air
        case .water: water
        }
    }
}
