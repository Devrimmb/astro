import SwiftUI

// Tasarım sisteminin küçük, tekrar eden parçaları. Ekranlar bunları kullanır;
// kendi rozet / satır / gösterge kopyasını yazmaz.

// MARK: - Pill

/// Küçük kapsül rozet — ton, kategori, Pro etiketi.
struct Pill: View {
    let text: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon).font(.system(size: 8, weight: .bold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: .capsule)
        .overlay { Capsule().stroke(color.opacity(0.3), lineWidth: 0.5) }
    }

    static func tone(_ tone: DailyCosmicCoach.Tone) -> Pill {
        switch tone {
        case .harmonik:  Pill(text: "Harmonik", color: AstroTheme.tone(tone), icon: "triangle")
        case .zorlayici: Pill(text: "Zorlayıcı", color: AstroTheme.tone(tone), icon: "square")
        case .notr:      Pill(text: "Nötr", color: AstroTheme.tone(tone), icon: "circle")
        }
    }

    static var pro: Pill {
        Pill(text: "Pro", color: AstroTheme.planet(.sun), icon: "sparkle")
    }
}

// MARK: - PlanetRow

/// Gezegen satırı: renkli glif rozeti · ad · burç · derece · ℞ · ev.
struct PlanetRow: View {
    let position: PlanetPosition
    var showHouse: Bool = true

    private var color: Color { AstroTheme.planet(position.planet) }

    var body: some View {
        HStack(spacing: 10) {
            Text(position.planet.glyph)
                .font(.subheadline)
                .fontDesign(.serif)
                .foregroundStyle(color)
                .frame(width: 26, height: 26)
                .background(color.opacity(0.12), in: .circle)
                .accessibilityHidden(true)

            Text(position.planet.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(spacing: 4) {
                Text(position.sign.glyph)
                    .fontDesign(.serif)
                    .foregroundStyle(AstroTheme.element(position.sign.element))
                Text(position.sign.name)
                    .foregroundStyle(AstroTheme.textSecondary)
                Text(String(format: "%.1f°", position.degree))
                    .foregroundStyle(AstroTheme.textTertiary)
                    .monospacedDigit()
            }
            .font(.caption)
            .lineLimit(1)

            Spacer(minLength: 4)

            if position.isRetrograde {
                Text("℞")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AstroTheme.zorlayici)
            }
            if showHouse {
                Text("\(position.house). ev")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AstroTheme.surface, in: .capsule)
            }
        }
    }
}

// MARK: - AspectRow

/// Açı satırı: iki renkli glif · başlık + alt satır · doğa renginde orb rozeti.
struct AspectRow: View {
    let glyph1: String
    let color1: Color
    let glyph2: String
    let color2: Color
    let title: String
    let subtitle: String
    let nature: AspectType.Nature
    let orb: Double

    private var natureColor: Color { AstroTheme.nature(nature) }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                Text(glyph1).foregroundStyle(color1)
                Text(glyph2).foregroundStyle(color2)
            }
            .font(.subheadline)
            .fontDesign(.serif)
            .frame(width: 40, alignment: .leading)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(String(format: "%.1f°", orb))
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(natureColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(natureColor.opacity(0.12), in: .rect(cornerRadius: 6))
        }
    }
}

extension AspectRow {
    /// Harita-içi açı; alt satır verilmezse yaklaşan/ayrılan bilgisi yazılır
    init(_ aspect: Aspect, subtitle: String? = nil) {
        self.init(
            glyph1: aspect.point1.glyph, color1: AstroTheme.point(aspect.point1),
            glyph2: aspect.point2.glyph, color2: AstroTheme.point(aspect.point2),
            title: "\(aspect.point1.name) \(aspect.type.turkishName) \(aspect.point2.name)",
            subtitle: subtitle ?? (aspect.applying ? "Yaklaşan" : "Ayrılan"),
            nature: aspect.type.nature,
            orb: aspect.orb
        )
    }

    /// Transit gezegen → natal gezegen
    init(_ aspect: TransitAspect) {
        self.init(
            glyph1: aspect.transitPlanet.glyph, color1: AstroTheme.planet(aspect.transitPlanet),
            glyph2: aspect.natalPlanet.glyph, color2: AstroTheme.planet(aspect.natalPlanet),
            title: "T. \(aspect.transitPlanet.name) \(aspect.type.turkishName) N. \(aspect.natalPlanet.name)",
            subtitle: aspect.applying ? "Yaklaşan" : "Ayrılan",
            nature: aspect.type.nature,
            orb: aspect.orb
        )
    }

    /// Kişi 1 gezegeni → kişi 2 gezegeni
    init(_ aspect: SynastryAspect, name1: String, name2: String) {
        self.init(
            glyph1: aspect.planet1.glyph, color1: AstroTheme.planet(aspect.planet1),
            glyph2: aspect.planet2.glyph, color2: AstroTheme.planet(aspect.planet2),
            title: "\(aspect.planet1.name) \(aspect.type.turkishName) \(aspect.planet2.name)",
            subtitle: "\(name1) → \(name2) · \(aspect.applying ? "Yaklaşan" : "Ayrılan")",
            nature: aspect.type.nature,
            orb: aspect.orb
        )
    }
}

// MARK: - DotMeter

/// 1–5 arası nokta göstergesi (aşk / kariyer / enerji puanları).
struct DotMeter: View {
    let value: Int
    var total: Int = 5
    var tint: Color = AstroTheme.accent
    var dotSize: CGFloat = 7

    var body: some View {
        HStack(spacing: dotSize * 0.6) {
            ForEach(0..<total, id: \.self) { i in
                let on = i < value
                Circle()
                    .fill(on ? tint : .white.opacity(0.08))
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: on ? tint.opacity(0.6) : .clear, radius: dotSize * 0.6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(total) üzerinden \(value)")
    }
}

// MARK: - ScoreRing

/// Tek sayı göstergesi — ilişki skoru, uyum yüzdesi, günlük enerji.
/// Sayı serif, değişince `numericText` ile akar.
struct ScoreRing: View {
    let value: Int
    var total: Int = 100
    var tint: Color = AstroTheme.accent
    var label: String? = nil
    var size: CGFloat = 100
    var lineWidth: CGFloat = 8

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(value) / Double(total), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.55), tint],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.35), radius: 8)
                .animation(.spring(duration: 0.8, bounce: 0.1), value: progress)

            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: size * 0.3, design: .serif))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                if let label {
                    Text(label.uppercased())
                        .font(.system(size: size * 0.08, weight: .semibold))
                        .kerning(1)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label ?? "Puan"): \(total) üzerinden \(value)")
    }
}
