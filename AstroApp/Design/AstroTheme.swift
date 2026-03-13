import SwiftUI

enum AstroTheme {
    // Arka plan — derin koyu, hafif mavi ton
    static let background = Color(red: 0.04, green: 0.05, blue: 0.12)
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
        colors: [
            Color(red: 0.04, green: 0.05, blue: 0.12),
            Color(red: 0.07, green: 0.06, blue: 0.18),
            Color(red: 0.04, green: 0.05, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBorder = Color.white.opacity(0.08)
}
