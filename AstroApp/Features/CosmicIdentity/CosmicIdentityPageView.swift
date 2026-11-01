import SwiftUI

/// Kozmik kimlik hikâyesinin tek sayfası. Doğrudan 1080×1920 tasarlanır; uygulamada ekrana
/// sığacak kadar küçültülür, paylaşımda aynı görünüm görsele çevrilir.
struct CosmicIdentityPageView: View {
    let page: CosmicIdentityPage
    let identity: CosmicIdentity
    /// false → öğeler gizli; true olunca sırayla belirir. Paylaşım görselinde hep true.
    var revealed: Bool = true

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

            // Başlık üstte, içerik dikeyde ortada, imza altta
            VStack(spacing: 0) {
                header
                Spacer(minLength: 40)
                Group {
                    switch page {
                    case .cover: cover
                    case .bigThree: bigThree
                    case .element: element
                    case .signature: signature
                    case .cycle: cycle
                    }
                }
                Spacer(minLength: 40)
                HStack(spacing: 10) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(purple)
                    Text("AstroApp")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 70)
            }
        }
        .frame(width: 1080, height: 1920)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Text("✦ \(title) ✦")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
                .tracking(4)
            if page != .cover, !identity.name.isEmpty {
                Text(identity.name)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(purple)
            }
        }
        .padding(.top, 90)
    }

    private var title: String {
        switch page {
        case .cover: "KOZMİK KİMLİK"
        case .bigThree: "BÜYÜK ÜÇLÜN"
        case .element: "ELEMENT DENGEN"
        case .signature: "HARİTANIN İMZASI"
        case .cycle: identity.nextCycle?.isActive == true ? "ŞU AN İÇİNDESİN" : "SIRADAKİ DÖNEMECİN"
        }
    }

    private var seed: UInt64 {
        UInt64(abs(Int(identity.chart.birthDate.timeIntervalSince1970))) &+ UInt64(page.rawValue)
    }

    // MARK: - Kapak

    private var cover: some View {
        VStack(spacing: 56) {
            Text(identity.name.isEmpty ? "Senin" : identity.name)
                .font(.system(size: 112, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 60)
                .reveal(revealed, delay: 0.1)
            ChartWheelView(chart: identity.chart, size: 860)
                .frame(width: 860, height: 860)
                .shadow(color: purple.opacity(0.35), radius: 40)
                .reveal(revealed, delay: 0.35, scale: 0.85)
            VStack(spacing: 16) {
                Text("Kozmik Kimliğin")
                    .font(.system(size: 64, weight: .semibold, design: .serif))
                    .foregroundStyle(purple)
                Text(identity.birthLine)
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .reveal(revealed, delay: 0.7)
        }
    }

    // MARK: - Büyük Üçlü

    private var bigThree: some View {
        let chart = identity.chart
        return VStack(spacing: 36) {
            if let sun = chart.sunSign {
                bigThreeRow(glyph: "☉", label: "GÜNEŞ · ÖZÜN", sign: sun, color: AstroTheme.planet(.sun))
                    .reveal(revealed, delay: 0.15)
            }
            if let moon = chart.moonSign {
                bigThreeRow(glyph: "☽", label: "AY · DUYGULARIN", sign: moon, color: AstroTheme.planet(.moon))
                    .reveal(revealed, delay: 0.45)
            }
            if let asc = chart.ascendant {
                bigThreeRow(glyph: "↑", label: "YÜKSELEN · DÜNYAYA YÜZÜN", sign: asc, color: AstroTheme.harmonik)
                    .reveal(revealed, delay: 0.75)
            }
        }
        .padding(.top, 40)
    }

    private func bigThreeRow(glyph: String, label: String, sign: ZodiacSign, color: Color) -> some View {
        shareGlassBox {
            HStack(spacing: 36) {
                Text(glyph + "\u{FE0E}")
                    .font(.system(size: 64, design: .serif))
                    .foregroundStyle(color)
                    .frame(width: 130, height: 130)
                    .background(color.opacity(0.15), in: .circle)
                VStack(alignment: .leading, spacing: 8) {
                    Text(label)
                        .font(.system(size: 24, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(sign.glyph) \(sign.name)")
                        .font(.system(size: 72, weight: .semibold, design: .serif))
                        .foregroundStyle(AstroTheme.element(sign.element))
                    Text(CosmicIdentityText.keywords(sign))
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Element

    private var element: some View {
        let percents = identity.elementPercents
        return VStack(spacing: 44) {
            if let top = percents.first {
                let color = AstroTheme.element(top.element)
                VStack(spacing: 16) {
                    Image(systemName: CosmicIdentityText.elementIcon(top.element))
                        .font(.system(size: 120))
                        .foregroundStyle(color)
                        .shadow(color: color.opacity(0.5), radius: 30)
                    Text(top.element.displayName)
                        .font(.system(size: 120, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Text("%\(top.percent) · baskın element")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(color)
                }
                .padding(.top, 20)
                .reveal(revealed, delay: 0.15, scale: 0.85)
            }

            VStack(spacing: 22) {
                ForEach(percents, id: \.element) { item in
                    elementBar(item.element, percent: item.percent)
                }
            }
            .padding(.horizontal, 80)
            .reveal(revealed, delay: 0.5)

            if let expr = identity.chart.dominantSignExpression {
                shareGlassBox {
                    Text("\(expr.element.displayName) elementin baskın ve \(expr.sign.name) burcu özelliği yansıtıyorsun.")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                .reveal(revealed, delay: 0.85)
            }
        }
    }

    private func elementBar(_ element: ZodiacSign.Element, percent: Int) -> some View {
        let color = AstroTheme.element(element)
        return HStack(spacing: 20) {
            Image(systemName: CosmicIdentityText.elementIcon(element))
                .font(.system(size: 30))
                .foregroundStyle(color)
                .frame(width: 44)
            Text(element.displayName)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 150, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule().fill(color)
                        .frame(width: revealed ? geo.size.width * CGFloat(percent) / 100 : 0)
                }
            }
            .frame(height: 18)
            Text("%\(percent)")
                .font(.system(size: 30, weight: .semibold).monospacedDigit())
                .foregroundStyle(color)
                .frame(width: 100, alignment: .trailing)
        }
    }

    // MARK: - İmza

    private var signature: some View {
        VStack(spacing: 44) {
            if let modality = identity.chart.dominantModality {
                VStack(spacing: 18) {
                    Text(CosmicIdentityText.modalityTitle(modality))
                        .font(.system(size: 96, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Text(CosmicIdentityText.modalityLine(modality))
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 90)
                }
                .padding(.top, 30)
                .reveal(revealed, delay: 0.15)
            }

            if let aspect = identity.strongestAspect {
                let item = ChartAspectInterpreter.interpretation(aspect, context: .natal)
                VStack(spacing: 24) {
                    Text("EN GÜÇLÜ AÇIN")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.5))
                    if let glyphs = item.glyphs {
                        Text(glyphs)
                            .font(.system(size: 110, design: .serif))
                            .foregroundStyle(purple)
                            .shadow(color: purple.opacity(0.5), radius: 30)
                    }
                    shareGlassBox {
                        VStack(spacing: 14) {
                            Text(item.title)
                                .font(.system(size: 42, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                        }
                    }
                }
                .reveal(revealed, delay: 0.55)
            }
        }
    }

    // MARK: - Döngü

    @ViewBuilder
    private var cycle: some View {
        if let highlight = identity.nextCycle {
            let event = highlight.event
            let color = AstroTheme.planet(event.kind.planet)
            VStack(spacing: 40) {
                Text(event.kind.planet.glyph)
                    .font(.system(size: 150, design: .serif))
                    .foregroundStyle(color)
                    .frame(width: 280, height: 280)
                    .background(color.opacity(0.15), in: .circle)
                    .shadow(color: color.opacity(0.5), radius: 40)
                    .padding(.top, 40)
                    .reveal(revealed, delay: 0.15, scale: 0.8)
                VStack(spacing: 18) {
                    Text(LifeCycleTiming.title(event))
                        .font(.system(size: 76, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(highlight.isActive ? LifeCycleTiming.dateRange(event, full: true) : LifeCycleTiming.countdown(to: event.start))
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(color)
                    Text("\(LifeCycleTiming.dateRange(event, full: true)) · \(LifeCycleTiming.ageText(event, birthDate: identity.chart.birthDate))")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .reveal(revealed, delay: 0.45)
                if let summary = LifeCycleInterpretation.entry(for: event.kind)?.summary {
                    shareGlassBox {
                        Text(summary)
                            .font(.system(size: 36))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                    }
                    .reveal(revealed, delay: 0.8)
                }
            }
        }
    }
}

// MARK: - Belirme animasyonu

private struct RevealModifier: ViewModifier {
    let revealed: Bool
    let delay: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(revealed ? 1 : 0)
            .scaleEffect(revealed ? 1 : scale)
            .offset(y: revealed ? 0 : 50)
            .animation(.spring(duration: 0.8, bounce: 0.2).delay(delay), value: revealed)
    }
}

extension View {
    fileprivate func reveal(_ revealed: Bool, delay: Double, scale: CGFloat = 1) -> some View {
        modifier(RevealModifier(revealed: revealed, delay: delay, scale: scale))
    }
}
