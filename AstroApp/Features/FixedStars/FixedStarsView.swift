import SwiftUI

struct FixedStarsView: View {
    @Environment(AppState.self) private var appState
    @State private var stars: [FixedStarPosition] = []
    @State private var conjunctions: [FixedStarConjunction] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Hesaplanıyor...")
                            .tint(AstroTheme.accent)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        if !conjunctions.isEmpty {
                            conjunctionsCard
                        }
                        allStarsCard
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Sabit Yıldızlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadData() }
    }

    private var conjunctionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "staroflife.fill")
                    .foregroundStyle(.yellow)
                Text("Haritanızdaki Yıldız Kavuşumları")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            Text("Natal gezegenlerinize 1.5° içinde kavuşum yapan sabit yıldızlar:")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)

            ForEach(conjunctions) { conj in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("★ \(conj.star.turkishName)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                        Text("☌")
                            .foregroundStyle(AstroTheme.accent)
                        Text(conj.planet.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Text(String(format: "%.1f°", conj.orb))
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    Text(conj.star.nature)
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(.vertical, 4)
                if conj.id != conjunctions.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    private var allStarsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .foregroundStyle(AstroTheme.accent)
                Text("Tüm Sabit Yıldızlar")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(stars) { star in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("★")
                                .foregroundStyle(.yellow)
                            Text(star.turkishName)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text("(\(star.name))")
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }
                        Text(star.nature)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Text(star.sign.glyph)
                                .font(.caption2)
                            Text("\(String(format: "%.1f", star.degree))°")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        Text("mag \(String(format: "%.1f", star.magnitude))")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                }
                .padding(.vertical, 2)
                if star.id != stars.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    private func loadData() async {
        isLoading = true
        let date = appState.currentChart?.birthDate ?? .now
        stars = FixedStarCalculator.calculatePositions(date: date)
        if let chart = appState.currentChart {
            conjunctions = FixedStarCalculator.findConjunctions(chart: chart, date: date)
        }
        isLoading = false
    }
}
