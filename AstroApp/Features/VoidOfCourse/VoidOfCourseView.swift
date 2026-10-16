import SwiftUI

struct VoidOfCourseView: View {
    @State private var vocPeriods: [VoidOfCourseMoon] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    infoCard
                    if isLoading {
                        ProgressView("Hesaplanıyor...")
                            .tint(AstroTheme.accent)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 20)
                    } else {
                        activeVOC
                        upcomingList
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Ay Boşlukta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadData() }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AstroTheme.accent)
                Text("Void of Course Moon Nedir?")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text("Ay, bulunduğu burçtaki son major açısını yaptıktan sonra yeni burca geçene kadar \"boşlukta\" kabul edilir. Bu dönemde yeni başlangıçlar, önemli kararlar ve anlaşmalar için uygun değildir.")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
                .lineSpacing(3)
        }
        .glassCard()
    }

    private var activeVOC: some View {
        let active = vocPeriods.first(where: { $0.isActive })
        return Group {
            if let voc = active {
                VStack(spacing: 10) {
                    Image(systemName: "moon.haze.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AstroTheme.water)

                    Text("Ay Şu An Boşlukta!")
                        .font(.headline)
                        .foregroundStyle(AstroTheme.water)

                    Text("\(voc.fromSign.name) → \(voc.toSign.name)")
                        .font(.subheadline)
                        .foregroundStyle(.white)

                    Text("Bitiş: \(voc.endText)")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)

                    Text("Kalan: \(voc.durationText)")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .glassCard()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AstroTheme.harmonik)
                    Text("Ay şu an boşlukta değil.")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.harmonik)
                }
                .glassCard()
            }
        }
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Önümüzdeki 7 Gün")
                .font(.headline)
                .foregroundStyle(.white)

            if vocPeriods.isEmpty {
                Text("Hesaplanan VOC dönemi yok.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                ForEach(vocPeriods) { voc in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(voc.startText) → \(voc.endText)")
                                .font(.caption.bold())
                                .foregroundStyle(voc.isActive ? AstroTheme.water : .white)
                            HStack(spacing: 4) {
                                Text("\(voc.fromSign.glyph) \(voc.fromSign.name)")
                                    .font(.caption2)
                                    .foregroundStyle(AstroTheme.textSecondary)
                                Text("→")
                                    .font(.caption2)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                Text("\(voc.toSign.glyph) \(voc.toSign.name)")
                                    .font(.caption2)
                                    .foregroundStyle(AstroTheme.textSecondary)
                            }
                        }
                        Spacer()
                        Text(voc.durationText)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    .padding(.vertical, 2)
                    if voc.id != vocPeriods.last?.id {
                        Divider().overlay(AstroTheme.cardBorder)
                    }
                }
            }
        }
        .glassCard()
    }

    private func loadData() async {
        isLoading = true
        vocPeriods = VoidOfCourseCalculator.calculate(fromDate: .now, days: 7)
        isLoading = false
    }
}
