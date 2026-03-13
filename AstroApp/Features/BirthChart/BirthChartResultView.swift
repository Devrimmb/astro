import SwiftUI

struct BirthChartResultView: View {
    @Environment(AppState.self) private var appState
    let chart: BirthChart

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    chartWheelCard
                    bigThreeCard
                    planetPositionsCard
                    housesCard
                    aspectsCard
                    interpretationsSection

                    // Aksiyon butonları
                    HStack(spacing: 12) {
                        Button {
                            let ownerName = appState.birthDataStore.ownerPerson?.name ?? ""
                            ShareImageRenderer.shareChart(chart: chart, ownerName: ownerName)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                            }
                            .glassButton()
                        }

                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Doğum Haritanız")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Chart Wheel

    private var chartWheelCard: some View {
        VStack(spacing: 8) {
            Text("Yıldız Haritası")
                .font(.headline)
                .foregroundStyle(.white)
            ChartWheelView(chart: chart, size: 340)
        }
        .glassCard()
    }

    // MARK: - Büyük Üçlü

    private var bigThreeCard: some View {
        VStack(spacing: 14) {
            Text("Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                bigThreeItem(label: "Güneş", sign: chart.sunSign, icon: "sun.max.fill", color: .orange)
                bigThreeItem(label: "Ay", sign: chart.moonSign, icon: "moon.fill", color: AstroTheme.accentSecondary)
                bigThreeItem(label: "Yükselen", sign: chart.ascendant, icon: "arrow.up.circle.fill", color: AstroTheme.accent)
            }
        }
        .glassCard()
    }

    private func bigThreeItem(label: String, sign: ZodiacSign?, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
            if let sign {
                Text(sign.glyph)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(sign.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(sign?.name ?? "bilinmiyor")")
    }

    // MARK: - Gezegen Pozisyonları

    private var planetPositionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gezegenler")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            ForEach(chart.planets) { position in
                HStack {
                    Text(position.planet.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(width: 95, alignment: .leading)
                    Text(position.sign.glyph)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(position.sign.name)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f°", position.degree))
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                    if position.isRetrograde {
                        Text("℞")
                            .foregroundStyle(AstroTheme.zorlayici)
                            .font(.caption2)
                    }
                    Text("Ev \(position.house)")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AstroTheme.surface, in: .capsule)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(position.planet.rawValue), \(position.sign.name), \(String(format: "%.0f", position.degree)) derece, \(position.house). ev\(position.isRetrograde ? ", retrograd" : "")")
                if position.planet != chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Evler

    private var housesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Evler")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(chart.houses) { house in
                    VStack(spacing: 3) {
                        Text("\(house.id)")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text(house.sign.glyph)
                            .font(.title3)
                        Text(String(format: "%.0f°", house.degree))
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
                }
            }
        }
        .glassCard()
    }

    // MARK: - Açılar

    private var aspectsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Açılar")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            if chart.aspects.isEmpty {
                Text("Açı bulunamadı")
                    .foregroundStyle(AstroTheme.textSecondary)
                    .font(.subheadline)
            } else {
                ForEach(Array(chart.aspects.prefix(10).enumerated()), id: \.offset) { _, aspect in
                    HStack {
                        Text(aspect.planet1.rawValue)
                            .font(.caption)
                            .frame(width: 65, alignment: .leading)
                        Text(aspectSymbol(aspect.type))
                            .font(.caption)
                        Text(aspect.planet2.rawValue)
                            .font(.caption)
                            .frame(width: 65, alignment: .leading)
                        Spacer()
                        Text(String(format: "%.1f°", aspect.orb))
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Circle()
                            .fill(aspectNatureColor(aspect.type.nature))
                            .frame(width: 6, height: 6)
                    }
                    .foregroundStyle(AstroTheme.textSecondary)
                }
                if chart.aspects.count > 10 {
                    Text("+\(chart.aspects.count - 10) açı daha")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yorumlar

    private var interpretationsSection: some View {
        let interpretation = appState.interpretation.interpret(chart: chart)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Yorumlar")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 2)

            if interpretation.sections.isEmpty {
                Text("Yorum bulunamadı.")
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                ForEach(interpretation.sections) { section in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            categoryDot(section.category)
                            Text(section.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        Text(section.body)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .lineLimit(3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yardımcılar

    private func aspectSymbol(_ type: AspectType) -> String {
        switch type {
        case .conjunction: "☌"
        case .sextile: "⚹"
        case .square: "□"
        case .trine: "△"
        case .opposition: "☍"
        }
    }

    private func aspectNatureColor(_ nature: AspectType.Nature) -> Color {
        switch nature {
        case .harmonik: AstroTheme.harmonik
        case .zorlayici: AstroTheme.zorlayici
        case .notr: AstroTheme.notr
        }
    }

    private func categoryDot(_ category: InterpretationCategory) -> some View {
        let color: Color = switch category {
        case .bigThree: .orange
        case .planetInSign: AstroTheme.accent
        case .planetInHouse: AstroTheme.accentSecondary
        case .houseInSign: .teal
        case .aspect: .orange
        case .element: AstroTheme.fire
        case .modality: .gray
        }
        return Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }
}
