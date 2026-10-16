import SwiftUI

/// Tüm paylaşım kartları için ortak şablon.
/// Gradient arka plan, yıldız efekti ve AstroApp branding sağlar.
struct ShareCardTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    let seed: UInt64
    @ViewBuilder let content: () -> Content

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920
    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.10, green: 0.06, blue: 0.22),
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            shareStarsOverlay(seed: seed)

            VStack(spacing: 36) {
                // Başlık
                VStack(spacing: 12) {
                    Text("✦ \(title) ✦")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(4)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(purple)
                    }
                }
                .padding(.top, 80)

                content()

                Spacer()

                // AstroApp branding
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(purple)
                    Text("AstroApp")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Yardımcılar

/// Paylaşım kartlarında ortak yıldız overlay
func shareStarsOverlay(seed: UInt64) -> some View {
    Canvas { context, size in
        var rng = StableShareRNG(seed: seed)
        for _ in 0..<120 {
            let x = CGFloat.random(in: 0...size.width, using: &rng)
            let y = CGFloat.random(in: 0...size.height, using: &rng)
            let radius = CGFloat.random(in: 0.5...2.0, using: &rng)
            let opacity = Double.random(in: 0.1...0.4, using: &rng)
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(opacity)))
        }
    }
}

/// Paylaşım kartlarında ortak cam efektli kutu
func shareGlassBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(.vertical, 28)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.horizontal, 40)
}

/// Paylaşım kartlarında skor renk skalası
func shareScoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: Color(red: 0.30, green: 0.85, blue: 0.65)
    case 60..<80: Color(red: 0.56, green: 0.44, blue: 1.0)
    case 40..<60: AstroTheme.planet(.sun)
    default: Color(red: 1.0, green: 0.40, blue: 0.45)
    }
}
