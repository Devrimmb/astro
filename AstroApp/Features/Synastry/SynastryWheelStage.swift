import SwiftUI

/// Synastry çarkının giriş sahnesi: iki kişinin halkası ekranın iki yanından dönerek gelip üst üste
/// oturur, kişiler arası açılar tek tek çizilir, uyum skoru bu sırada 0'dan sayarak dolar.
/// Sahne bitince bir gezegene dokunmak yalnızca onun karşı haritaya açılarını bırakır.
struct SynastryWheelStage: View {
    let result: SynastryResult
    let name1: String
    let name2: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date?
    @State private var finished = false
    @State private var selection: SynastryBiWheelView.Selection?

    private let wheelSize: CGFloat = 320

    /// Halkaların yerine oturma süresi (sn)
    private static let entrance = 1.1
    /// Ardışık iki açının başlangıçları arası (sn)
    private static let step = 0.2

    private var aspectCount: Int {
        SynastryBiWheelView.visibleAspects(result.crossAspects, selection: nil).count
    }

    private var totalDuration: Double {
        Self.entrance + (Double(max(aspectCount - 1, 0)) + SynastryBiWheelView.drawSteps) * Self.step
    }

    private var score: Int { result.aspectBasedScore }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Synastry Haritası")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            HStack {
                ringLabel(name1, ring: "iç halka", tint: .white)
                Spacer()
                ringLabel(name2, ring: "dış halka", tint: .white.opacity(0.7))
            }

            TimelineView(.animation(paused: finished)) { timeline in
                let t = elapsed(at: timeline.date)
                VStack(spacing: 14) {
                    wheels(t: t)
                    hint
                    scoreRow(t: t)
                }
                // Skor her 5 puanda bir tıklar; sayım hızlandıkça tıklar sıklaşır ve güçlenir
                .onChange(of: shownScore(t: t) / 5) { old, new in
                    if new > old { AstroHaptics.tick(0.3 + 0.5 * Double(new * 5) / 100) }
                }
                .onChange(of: t >= totalDuration) { _, done in
                    if done { finished = true }
                }
            }

            HStack(spacing: 12) {
                legendDot(AstroTheme.harmonik, "Harmonik")
                legendDot(AstroTheme.zorlayici, "Zorlayıcı")
                legendDot(AstroTheme.notr, "Nötr")
            }
        }
        .glassCard()
        .onChange(of: finished) { old, new in
            if new && !old && !reduceMotion { AstroHaptics.scoreFinale() }
        }
        .astroFeedback(.selection, trigger: selection)
        .onAppear {
            AstroHaptics.prepare()
            if reduceMotion {
                finished = true
            } else if start == nil {
                start = .now
            }
        }
    }

    // MARK: - Çark

    private func wheels(t: Double) -> some View {
        let e = Self.easeOutBack(min(max(t / Self.entrance, 0), 1))
        let away = 1 - e
        return ZStack {
            wheel(layers: .outer)
                .rotationEffect(.degrees(120 * away))
                .offset(x: wheelSize * 0.85 * away)
            wheel(layers: .inner)
                .rotationEffect(.degrees(-120 * away))
                .offset(x: -wheelSize * 0.85 * away)
            wheel(layers: .aspects, clock: (t - Self.entrance) / Self.step) { hit in
                handleTap(hit)
            }
        }
        .opacity(min(t / 0.35, 1))
        .frame(width: wheelSize, height: wheelSize)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Synastry haritası: iç halka \(name1), dış halka \(name2), \(aspectCount) belirgin açı")
    }

    private func wheel(
        layers: SynastryBiWheelView.Layers,
        clock: Double = .infinity,
        onTap: ((SynastryBiWheelView.Selection?) -> Void)? = nil
    ) -> some View {
        SynastryBiWheelView(
            chart1: result.chart1,
            chart2: result.chart2,
            crossAspects: result.crossAspects,
            size: wheelSize,
            layers: layers,
            aspectClock: clock,
            selection: selection,
            onTap: onTap
        )
    }

    /// Sahne sürerken dokunmak sahneyi bitirir; sonra gezegen seçer / seçimi kaldırır
    private func handleTap(_ hit: SynastryBiWheelView.Selection?) {
        guard finished else {
            finished = true
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            selection = (hit == nil || hit == selection) ? nil : hit
        }
    }

    private var hint: some View {
        Group {
            if !finished {
                Text("Atlamak için dokun")
                    .foregroundStyle(AstroTheme.textTertiary)
            } else if let selection {
                let owner = selection.isPerson1 ? name1 : name2
                let other = selection.isPerson1 ? name2 : name1
                let count = SynastryBiWheelView.visibleAspects(result.crossAspects, selection: selection).count
                Text(count == 0
                     ? "\(selection.planet.glyph) \(selection.planet.name) (\(owner)) ile \(other) arasında belirgin açı yok"
                     : "\(selection.planet.glyph) \(owner) · \(selection.planet.name) → \(other): \(count) açı")
                    .foregroundStyle(AstroTheme.planet(selection.planet))
            } else {
                Text("Bir gezegene dokun: yalnızca onun açıları kalır")
                    .foregroundStyle(AstroTheme.textTertiary)
            }
        }
        .font(.caption2)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skor

    private func scoreRow(t: Double) -> some View {
        let shown = shownScore(t: t)
        return HStack(spacing: 16) {
            ScoreRing(value: shown, total: 100, tint: Self.scoreColor(score), label: "/ 100", size: 84, lineWidth: 7, animated: false)
            VStack(alignment: .leading, spacing: 4) {
                Text("ASPECT BAZLI UYUM")
                    .font(.system(size: 9, weight: .semibold))
                    .kerning(1.2)
                    .foregroundStyle(AstroTheme.textTertiary)
                Text(Self.scoreText(score))
                    .font(.headline)
                    .foregroundStyle(Self.scoreColor(score))
                    .opacity(finished ? 1 : 0)
                Text("\(result.crossAspects.count) cross-aspect analizi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Zaman

    private func elapsed(at date: Date) -> Double {
        guard !finished else { return .infinity }
        guard let start else { return 0 }
        return date.timeIntervalSince(start)
    }

    /// O an gösterilen skor: açılar çizilirken hızlanarak sayar (sona doğru sıklaşan tıklar, sonunda güçlü vuruş)
    private func shownScore(t: Double) -> Int {
        guard !finished else { return score }
        let x = min(max((t - Self.entrance) / (totalDuration - Self.entrance), 0), 1)
        return Int((Double(score) * x * x).rounded())
    }

    /// Hafif taşıp yerine oturan eğri
    private static func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.2
        let c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }

    // MARK: - Görünüm yardımcıları

    private func ringLabel(_ name: String, ring: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Label(name, systemImage: tint == .white ? "person.fill" : "person")
                .foregroundStyle(tint)
            Text("(\(ring))")
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .font(.caption2)
        .lineLimit(1)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7)
            Text(label).font(.system(size: 9)).foregroundStyle(AstroTheme.textTertiary)
        }
    }

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 70...100: AstroTheme.harmonik
        case 50..<70: AstroTheme.accent
        case 30..<50: AstroTheme.planet(.sun)
        default: AstroTheme.zorlayici
        }
    }

    static func scoreText(_ score: Int) -> String {
        switch score {
        case 80...100: "Mükemmel Uyum"
        case 65..<80: "Güçlü Uyum"
        case 50..<65: "İyi Uyum"
        case 35..<50: "Zorlu Uyum"
        default: "Karmaşık Dinamik"
        }
    }
}
