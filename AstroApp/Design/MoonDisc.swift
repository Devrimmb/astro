import SwiftUI

/// Canvas ile çizilen Ay — aydınlanma oranı ve büyüyen/küçülen yönüne göre
/// terminatör (gölge sınırı) hesaplanır. SF Symbol/emoji yerine kullanılır.
struct MoonDisc: View {
    /// 0 (yeni ay) … 1 (dolunay)
    let illumination: Double
    /// Büyüyen ayda aydınlık taraf sağda, küçülende solda (kuzey yarımküre)
    let isWaxing: Bool
    var size: CGFloat = 120
    /// Çevresinde yumuşak ışıma — küçük boyutlarda kapatılır
    var glow: Bool = true

    init(illumination: Double, isWaxing: Bool, size: CGFloat = 120, glow: Bool = true) {
        self.illumination = illumination
        self.isWaxing = isWaxing
        self.size = size
        self.glow = glow
    }

    init(info: MoonPhaseInfo, size: CGFloat = 120, glow: Bool = true) {
        self.init(illumination: info.illumination, isWaxing: info.phase.isWaxing, size: size, glow: glow)
    }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 * (glow ? 0.76 : 0.96)
            let discRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

            if glow {
                let glowRadius = radius * 1.3
                let glowRect = CGRect(x: center.x - glowRadius, y: center.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [AstroTheme.planet(.moon).opacity(0.28 * illumination + 0.06), .clear]),
                        center: center, startRadius: radius * 0.9, endRadius: glowRadius
                    )
                )
            }

            // Karanlık yüz
            context.fill(Path(ellipseIn: discRect), with: .color(Color(red: 0.09, green: 0.10, blue: 0.22)))

            // Aydınlık bölge + kraterler (aydınlık alana kırpılır)
            let lit = litPath(center: center, radius: radius)
            context.drawLayer { layer in
                layer.clip(to: lit)
                layer.fill(
                    Path(ellipseIn: discRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            .white,
                            Color(red: 0.85, green: 0.87, blue: 0.96),
                            Color(red: 0.66, green: 0.69, blue: 0.81)
                        ]),
                        center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.3),
                        startRadius: 0, endRadius: radius * 1.5
                    )
                )
                for (dx, dy, cr) in [(0.28, -0.32, 0.11), (0.42, 0.18, 0.16), (0.02, 0.44, 0.08), (-0.3, 0.1, 0.07)] {
                    let craterRadius = radius * cr
                    let rect = CGRect(x: center.x + radius * dx - craterRadius, y: center.y + radius * dy - craterRadius,
                                      width: craterRadius * 2, height: craterRadius * 2)
                    layer.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.08)))
                }
            }

            context.stroke(Path(ellipseIn: discRect), with: .color(.white.opacity(0.12)), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// Aydınlık bölgenin yolu: aydınlık taraftaki dış yay + terminatör yarı-elipsi.
    /// k = aydınlanma; terminatör yarı-genişliği r·cos(πk) → k<0.5 hilal, k>0.5 şişkin.
    private func litPath(center: CGPoint, radius: CGFloat) -> Path {
        let k = min(max(illumination, 0), 1)
        let side: CGFloat = isWaxing ? 1 : -1
        let terminatorHalfWidth = radius * CGFloat(Foundation.cos(.pi * k))
        let steps = 48

        var path = Path()
        for i in 0...steps {
            let t = Double(i) / Double(steps) * .pi
            let point = CGPoint(x: center.x + side * radius * CGFloat(Foundation.sin(t)),
                                y: center.y - radius * CGFloat(Foundation.cos(t)))
            i == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        for i in 0...steps {
            let t = .pi - Double(i) / Double(steps) * .pi
            path.addLine(to: CGPoint(x: center.x + side * terminatorHalfWidth * CGFloat(Foundation.sin(t)),
                                     y: center.y - radius * CGFloat(Foundation.cos(t))))
        }
        path.closeSubpath()
        return path
    }
}

extension MoonPhaseName {
    var isWaxing: Bool {
        switch self {
        case .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous: true
        case .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent: false
        }
    }
}
