import SwiftUI

// Widget'ın görsel çekirdeği: bugünün gökyüzü çarkı (12 burç dilimi, gerçek
// boylamlarda gezegenler, aralarındaki majör açılar) ve merkezde gerçek Ay evresi.
// Uygulamadaki ChartWheelView / MoonDisc ile aynı dil; widget hedefi ayrı modül
// olduğu için küçük kopyalar burada tutulur.

// MARK: - Palet

enum WidgetPalette {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.12)
    static let backgroundMid = Color(red: 0.07, green: 0.06, blue: 0.18)
    static let accent = Color(red: 0.56, green: 0.44, blue: 1.0)
    static let gold = Color(red: 0.91, green: 0.78, blue: 0.49)
    static let retro = Color(red: 1.0, green: 0.40, blue: 0.45)
    static let harmonik = Color(red: 0.30, green: 0.85, blue: 0.65)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.3)

    static func element(_ element: String) -> Color {
        switch element {
        case "fire":  Color(red: 1.0, green: 0.45, blue: 0.42)
        case "earth": Color(red: 0.42, green: 0.82, blue: 0.52)
        case "air":   Color(red: 1.0, green: 0.85, blue: 0.35)
        default:      Color(red: 0.40, green: 0.68, blue: 1.0)
        }
    }

    static func planet(_ symbol: String) -> Color {
        switch symbol {
        case "☉": Color(red: 1.0, green: 0.80, blue: 0.40)
        case "☽": Color(red: 0.85, green: 0.88, blue: 1.0)
        case "☿": Color(red: 0.64, green: 0.86, blue: 0.80)
        case "♀": Color(red: 1.0, green: 0.54, blue: 0.72)
        case "♂": Color(red: 1.0, green: 0.47, blue: 0.42)
        case "♃": Color(red: 1.0, green: 0.68, blue: 0.42)
        case "♄": Color(red: 0.79, green: 0.64, blue: 0.49)
        case "⛢": Color(red: 0.49, green: 0.85, blue: 0.95)
        case "♆": Color(red: 0.48, green: 0.55, blue: 1.0)
        case "♇": Color(red: 0.72, green: 0.56, blue: 1.0)
        default:  Color.white.opacity(0.7)
        }
    }

    static func aspect(_ angle: Int) -> Color {
        switch angle {
        case 0:        gold
        case 60, 120:  harmonik
        default:       retro
        }
    }
}

// MARK: - Gökyüzü çarkı

struct WidgetSkyWheel: View {
    let planets: [WidgetPlanetInfo]
    let moon: WidgetMoonInfo
    var size: CGFloat = 128

    private struct Aspect { let a: Int; let b: Int; let angle: Int }

    var body: some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let R = min(canvasSize.width, canvasSize.height) / 2 - 1
            let signInner = R * 0.84
            let planetRadius = R * 0.67
            let aspectRadius = R * 0.50
            let moonRadius = R * 0.30

            // Dış ışıma
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - R, y: center.y - R, width: R * 2, height: R * 2)),
                     with: .radialGradient(Gradient(colors: [WidgetPalette.accent.opacity(0.16), .clear]),
                                           center: center, startRadius: R * 0.3, endRadius: R))

            // Burç halkası — element tonlu 12 dilim
            for (i, sign) in WidgetZodiacSign.allCases.enumerated() {
                let start = Double(i) * 30, end = start + 30
                let path = ringSegment(center: center, inner: signInner, outer: R, from: start, to: end)
                ctx.fill(path, with: .color(WidgetPalette.element(sign.element).opacity(0.22)))
                ctx.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.5)

                let glyph = Text(sign.glyph)
                    .font(.system(size: R * 0.15, design: .serif))
                    .foregroundColor(WidgetPalette.element(sign.element))
                ctx.draw(ctx.resolve(glyph), at: point(center, (R + signInner) / 2, start + 15), anchor: .center)
            }
            for r in [R, signInner] {
                ctx.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                           with: .color(.white.opacity(0.18)), lineWidth: 0.6)
            }

            // Majör açılar (merkezde)
            for asp in aspects() {
                let p1 = point(center, aspectRadius, planets[asp.a].wheelLongitude)
                let p2 = point(center, aspectRadius, planets[asp.b].wheelLongitude)
                var line = Path()
                line.move(to: p1)
                line.addLine(to: p2)
                let dash: [CGFloat] = asp.angle == 60 ? [2, 2] : []
                ctx.stroke(line, with: .color(WidgetPalette.aspect(asp.angle).opacity(0.55)),
                           style: StrokeStyle(lineWidth: 0.8, dash: dash))
            }

            // Merkez: Ay
            drawMoon(ctx: &ctx, center: center, radius: moonRadius)

            // Gezegenler — çakışanlar hafifçe ayrılır, tik işareti gerçek boylamda
            let display = spreadLongitudes(planets.map(\.wheelLongitude), minGap: 13)
            for (i, p) in planets.enumerated() {
                let color = WidgetPalette.planet(p.symbol)
                var tick = Path()
                tick.move(to: point(center, signInner - 1, p.wheelLongitude))
                tick.addLine(to: point(center, signInner - R * 0.06, p.wheelLongitude))
                ctx.stroke(tick, with: .color(color.opacity(0.7)), lineWidth: 0.8)

                let pt = point(center, planetRadius, display[i])
                let badge = R * 0.105
                let badgeRect = CGRect(x: pt.x - badge, y: pt.y - badge, width: badge * 2, height: badge * 2)
                ctx.fill(Path(ellipseIn: badgeRect), with: .color(WidgetPalette.background.opacity(0.92)))
                ctx.stroke(Path(ellipseIn: badgeRect),
                           with: .color(p.isRetrograde ? WidgetPalette.retro : color.opacity(0.55)),
                           lineWidth: p.isRetrograde ? 1.1 : 0.7)
                let glyph = Text(p.symbol)
                    .font(.system(size: R * 0.165, design: .serif))
                    .foregroundColor(p.isRetrograde ? WidgetPalette.retro : color)
                ctx.draw(ctx.resolve(glyph), at: pt, anchor: .center)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Bugünün gökyüzü çarkı")
    }

    // MARK: Ay

    private func drawMoon(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let k = min(max(moon.illumination, 0), 1)
        let disc = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        let glowR = radius * 1.45
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR, width: glowR * 2, height: glowR * 2)),
                 with: .radialGradient(Gradient(colors: [WidgetPalette.planet("☽").opacity(0.26 * k + 0.05), .clear]),
                                       center: center, startRadius: radius * 0.9, endRadius: glowR))
        ctx.fill(Path(ellipseIn: disc), with: .color(Color(red: 0.09, green: 0.10, blue: 0.22)))

        let side: CGFloat = moon.phase.isWaxing ? 1 : -1
        let termHalf = radius * CGFloat(Foundation.cos(.pi * k))
        var lit = Path()
        let steps = 40
        for i in 0...steps {
            let t = Double(i) / Double(steps) * .pi
            let p = CGPoint(x: center.x + side * radius * CGFloat(Foundation.sin(t)),
                            y: center.y - radius * CGFloat(Foundation.cos(t)))
            i == 0 ? lit.move(to: p) : lit.addLine(to: p)
        }
        for i in 0...steps {
            let t = .pi - Double(i) / Double(steps) * .pi
            lit.addLine(to: CGPoint(x: center.x + side * termHalf * CGFloat(Foundation.sin(t)),
                                    y: center.y - radius * CGFloat(Foundation.cos(t))))
        }
        lit.closeSubpath()

        ctx.drawLayer { layer in
            layer.clip(to: lit)
            layer.fill(Path(ellipseIn: disc),
                       with: .radialGradient(Gradient(colors: [.white,
                                                               Color(red: 0.85, green: 0.87, blue: 0.96),
                                                               Color(red: 0.66, green: 0.69, blue: 0.81)]),
                                             center: CGPoint(x: center.x - radius * 0.25, y: center.y - radius * 0.3),
                                             startRadius: 0, endRadius: radius * 1.5))
            for (dx, dy, cr) in [(0.28, -0.32, 0.11), (0.42, 0.18, 0.16), (0.02, 0.44, 0.08), (-0.3, 0.1, 0.07)] {
                let r = radius * cr
                let rect = CGRect(x: center.x + radius * dx - r, y: center.y + radius * dy - r, width: r * 2, height: r * 2)
                layer.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.08)))
            }
        }
        ctx.stroke(Path(ellipseIn: disc), with: .color(.white.opacity(0.14)), lineWidth: 0.5)
    }

    // MARK: Geometri

    /// 0° Koç solda (saat 9), boylam saat yönünün tersine artar — natal çarkla aynı.
    private func point(_ c: CGPoint, _ r: CGFloat, _ lon: Double) -> CGPoint {
        let a = (180 - lon) * .pi / 180
        return CGPoint(x: c.x + r * CGFloat(Foundation.cos(a)), y: c.y - r * CGFloat(Foundation.sin(a)))
    }

    private func ringSegment(center: CGPoint, inner: CGFloat, outer: CGFloat, from: Double, to: Double) -> Path {
        var path = Path()
        let steps = 8
        for i in 0...steps {
            let lon = from + (to - from) * Double(i) / Double(steps)
            let p = point(center, outer, lon)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let lon = from + (to - from) * Double(i) / Double(steps)
            path.addLine(to: point(center, inner, lon))
        }
        path.closeSubpath()
        return path
    }

    private func spreadLongitudes(_ lons: [Double], minGap: Double) -> [Double] {
        var items = lons.enumerated().map { ($0.offset, $0.element) }.sorted { $0.1 < $1.1 }
        guard items.count > 1 else { return lons }
        for _ in 0..<6 {
            for i in 0..<items.count {
                let j = (i + 1) % items.count
                var gap = items[j].1 - items[i].1
                if gap < 0 { gap += 360 }
                if gap < minGap {
                    let push = (minGap - gap) / 2
                    items[i].1 -= push
                    items[j].1 += push
                }
            }
        }
        var out = lons
        for (idx, lon) in items { out[idx] = lon }
        return out
    }

    private func aspects() -> [Aspect] {
        guard planets.contains(where: { $0.longitude != nil }) else { return [] }
        let table: [(Int, Double)] = [(0, 7), (60, 4), (90, 6), (120, 6), (180, 7)]
        var out: [Aspect] = []
        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                var d = abs(planets[i].wheelLongitude - planets[j].wheelLongitude)
                if d > 180 { d = 360 - d }
                if let hit = table.first(where: { abs(d - Double($0.0)) <= $0.1 }) {
                    out.append(Aspect(a: i, b: j, angle: hit.0))
                }
            }
        }
        return out
    }
}

extension WidgetMoonPhase {
    var isWaxing: Bool {
        switch self {
        case .newMoon, .waxingCrescent, .firstQuarter, .waxingGibbous: true
        case .fullMoon, .waningGibbous, .lastQuarter, .waningCrescent: false
        }
    }
}

// MARK: - Yıldızlı zemin

/// Widget arka planı: koyu gradyan + sabit tohumlu yıldızlar + lavanta ışıma.
struct WidgetSkyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [WidgetPalette.backgroundMid, WidgetPalette.background],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [WidgetPalette.accent.opacity(0.22), .clear],
                           center: .init(x: 0.25, y: 0.1), startRadius: 0, endRadius: 220)
            Canvas { ctx, size in
                var rng = WidgetRNG(seed: 42)
                for _ in 0..<70 {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let r = CGFloat.random(in: 0.3...1.1, using: &rng)
                    let a = Double.random(in: 0.15...0.5, using: &rng)
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(.white.opacity(a)))
                }
            }
        }
    }
}

struct WidgetRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
