import SwiftUI

/// Bir `ChartSynthesizer.Synthesis` sonucunu görsel olarak render eder:
/// **Genel Değerlendirme** + **Öne Çıkan Kalıplar** + tona göre **gruplar**.
///
/// Composite, Synastry ve Solar Return (sonra Birth Chart) ortak kullanır —
/// bütüncül yorum sunumu tek yerde tanımlı kalsın diye.
struct ChartSynthesisSection: View {
    let synthesis: ChartSynthesizer.Synthesis

    var body: some View {
        VStack(spacing: 16) {
            summaryCard(synthesis.summary)

            if !synthesis.patterns.isEmpty {
                patternsCard(synthesis.patterns)
            }

            ForEach(synthesis.groups) { group in
                groupCard(group)
            }
        }
    }

    // MARK: - Genel Değerlendirme (özet)

    private func summaryCard(_ item: DailyCosmicCoach.GuidanceItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .foregroundStyle(toneColor(item.tone))
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text(item.message)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Öne Çıkan Kalıplar

    private func patternsCard(_ patterns: [DailyCosmicCoach.GuidanceItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(AstroTheme.accent)
                Text("Öne Çıkan Kalıplar")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            ForEach(patterns) { item in
                guidanceRow(item)
                if item.id != patterns.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Tona göre gruplar

    private func groupCard(_ group: ChartSynthesizer.ToneGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: groupIcon(group.tone))
                    .foregroundStyle(toneColor(group.tone))
                Text(group.title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            ForEach(group.items) { item in
                guidanceRow(item)
                if item.id != group.items.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func guidanceRow(_ item: DailyCosmicCoach.GuidanceItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.caption2)
                    .foregroundStyle(toneColor(item.tone))
                    .frame(width: 16)
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                if let glyphs = item.glyphs {
                    Spacer()
                    Text(glyphs)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(toneColor(item.tone))
                }
            }
            Text(item.message)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    // MARK: - Renk / ikon

    private func toneColor(_ tone: DailyCosmicCoach.Tone) -> Color {
        switch tone {
        case .harmonik:  AstroTheme.harmonik
        case .zorlayici: AstroTheme.zorlayici
        case .notr:      AstroTheme.accent
        }
    }

    private func groupIcon(_ tone: DailyCosmicCoach.Tone) -> String {
        switch tone {
        case .harmonik:  "checkmark.seal.fill"
        case .zorlayici: "exclamationmark.triangle.fill"
        case .notr:      "circle.hexagonpath.fill"
        }
    }
}
