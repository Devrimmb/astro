import SwiftUI

/// Cam kart. iOS 26+ sistem Liquid Glass'ını kullanır; altında kendi
/// material + kenar çizgisi fallback'i çalışır. Çağıran kod iki durumda da aynı.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    /// Hero kartlar için renk tonu (ör. `AstroTheme.accent`). nil → nötr cam.
    var tint: Color? = nil

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(padding)
                .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
                .overlay(alignment: .top) { specularLine }
        } else {
            content
                .padding(padding)
                .background { legacyBackground }
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        if let tint {
            .regular.tint(tint.opacity(0.18))
        } else {
            .regular
        }
    }

    /// Üst kenarda 1px ışık çizgisi — iki dalda da aynı görünüm
    private var specularLine: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [AstroTheme.cardSpecular, .clear],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
    }

    private var legacyBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return shape
            .fill(.ultraThinMaterial.opacity(0.5))
            .background {
                shape.fill(AstroTheme.surface)
                if let tint {
                    shape.fill(
                        LinearGradient(
                            colors: [tint.opacity(0.18), tint.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay {
                shape.stroke(tint.map { $0.opacity(0.3) } ?? AstroTheme.cardBorder, lineWidth: 1)
            }
            .overlay(alignment: .top) { specularLine }
    }
}

/// Birincil aksiyon butonu görünümü — capsule, accent gradient.
struct GlassButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background {
                Capsule()
                    .fill(AstroTheme.accentGradient)
                    .overlay {
                        Capsule().stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                    }
                    .shadow(color: AstroTheme.accent.opacity(0.35), radius: 12, y: 6)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 16, tint: Color? = nil) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding, tint: tint))
    }

    func glassButton() -> some View {
        modifier(GlassButton())
    }
}
