import SwiftUI

struct MoonPhaseView: View {
    @State private var currentPhase = MoonPhaseCalculator.currentPhase()
    @State private var upcomingPhases = MoonPhaseCalculator.upcomingPhases(count: 8)

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        currentPhaseCard
                        moonEnergyCard
                        upcomingPhasesCard
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Ay Evreleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Mevcut Evre

    private var currentPhaseCard: some View {
        VStack(spacing: 16) {
            MoonDisc(info: currentPhase, size: 170)

            Text(currentPhase.phase.name)
                .font(.title)
                .fontDesign(.serif)
                .foregroundStyle(.white)

            Text("Aydınlanma: %\(Int(currentPhase.illumination * 100))")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.accentSecondary)

            if let sign = currentPhase.moonSign {
                HStack(spacing: 6) {
                    Text("Ay şu anda")
                        .foregroundStyle(AstroTheme.textSecondary)
                    Text("\(sign.glyph) \(sign.name)")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    Text("burcunda")
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .font(.caption)
            }

            Text(currentPhase.phase.description)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentPhase.phase.name), aydınlanma yüzde \(Int(currentPhase.illumination * 100))")
    }

    // MARK: - Ay Enerjisi

    private var moonEnergyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AstroTheme.accent)
                Text("Ay Enerjisi")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(currentPhase.phase.energies, id: \.self) { energy in
                HStack(spacing: 8) {
                    Circle()
                        .fill(AstroTheme.accent.opacity(0.6))
                        .frame(width: 5, height: 5)
                    Text(energy)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yaklaşan Evreler

    private var upcomingPhasesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yaklaşan Evreler")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(upcomingPhases, id: \.date) { info in
                HStack {
                    MoonDisc(info: info, size: 28, glow: false)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.phase.name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text(info.dateText)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    Spacer()
                    Text("%\(Int(info.illumination * 100))")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(info.phase.name), \(info.dateText)")

                if info.date != upcomingPhases.last?.date {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }
}
