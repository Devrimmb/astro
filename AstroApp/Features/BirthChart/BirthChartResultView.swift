import SwiftUI

struct BirthChartResultView: View {
    @Environment(AppState.self) private var appState
    let chart: BirthChart
    let personName: String
    @State private var selectedHouse: House?

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    chartWheelCard
                    bigThreeCard
                    elementBalanceCard
                    planetPositionsCard
                    housesCard
                    aspectsCard
                    interpretationsSection

                    // Aksiyon butonları
                    HStack(spacing: 12) {
                        Button {
                            ShareImageRenderer.shareChart(chart: chart, ownerName: personName)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                            }
                            .glassButton()
                        }

                        Button {
                            ChartPDFExporter.exportAndShare(
                                chart: chart,
                                ownerName: personName,
                                interpretation: appState.interpretation
                            )
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.richtext")
                                Text("PDF")
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

    // MARK: - Element & Modalite Dengesi

    private var elementBalanceCard: some View {
        let elements = chart.elementBalance
        let modalities = chart.modalityBalance
        let totalPlanets = chart.planets.count

        return VStack(spacing: 14) {
            Text("Element & Modalite Dengesi")
                .font(.headline)
                .foregroundStyle(.white)

            // Elementler
            VStack(spacing: 8) {
                ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                    let count = elements[element, default: 0]
                    let ratio = totalPlanets > 0 ? Double(count) / Double(totalPlanets) : 0

                    HStack(spacing: 10) {
                        Text(elementIcon(element))
                            .font(.title3)
                            .frame(width: 28)

                        Text(element.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(width: 55, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.08))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(elementColor(element))
                                    .frame(width: geo.size.width * ratio)
                            }
                        }
                        .frame(height: 10)

                        Text("\(count)")
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(elementColor(element))
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }

            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 8)

            // Modaliteler
            HStack(spacing: 0) {
                ForEach(ZodiacSign.Modality.allCases, id: \.self) { modality in
                    let count = modalities[modality, default: 0]

                    VStack(spacing: 6) {
                        Text(modalityIcon(modality))
                            .font(.title3)
                        Text(modality.displayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AstroTheme.textSecondary)
                        Text("\(count)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glassCard()
    }

    private func elementIcon(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire: "🔥"
        case .earth: "🌍"
        case .air: "💨"
        case .water: "💧"
        }
    }

    private func elementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire: AstroTheme.fire
        case .earth: .green
        case .air: .yellow
        case .water: .blue
        }
    }

    private func modalityIcon(_ modality: ZodiacSign.Modality) -> String {
        switch modality {
        case .cardinal: "⚡"
        case .fixed: "🪨"
        case .mutable: "🌀"
        }
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
                    Text(position.planet.name)
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
                .accessibilityLabel("\(position.planet.name), \(position.sign.name), \(String(format: "%.0f", position.degree)) derece, \(position.house). ev\(position.isRetrograde ? ", retrograd" : "")")
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
            HStack {
                Text("Evler")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Dokun → Yorum")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(chart.houses) { house in
                    let hasInterpretation = HouseSignInterpretation.interpretation(house: house.id, zodiacSign: house.sign) != nil
                    Button {
                        selectedHouse = house
                    } label: {
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
                        .overlay {
                            if hasInterpretation {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AstroTheme.accent.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
        .glassCard()
        .sheet(item: $selectedHouse) { house in
            HouseInterpretationSheet(house: house)
        }
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
                ForEach(Array(chart.aspects.enumerated()), id: \.offset) { _, aspect in
                    HStack {
                        Text(aspect.planet1.name)
                            .font(.caption)
                            .frame(width: 65, alignment: .leading)
                        Text(aspectSymbol(aspect.type))
                            .font(.caption)
                        Text(aspect.planet2.name)
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

// MARK: - Ev Yorum Sheet

private struct HouseInterpretationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let house: House

    private var entry: HouseSignEntry? {
        HouseSignInterpretation.interpretation(house: house.id, zodiacSign: house.sign)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Ev başlığı
                        VStack(spacing: 8) {
                            Text(house.sign.glyph)
                                .font(.system(size: 48))
                            Text("\(house.id). Ev — \(house.sign.name)")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            Text(String(format: "%.1f°", house.degree))
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                        }
                        .padding(.top, 8)

                        // Yorum
                        if let entry {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Yorum")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text(entry.description)
                                    .font(.subheadline)
                                    .foregroundStyle(AstroTheme.textSecondary)
                                    .lineSpacing(4)
                            }
                            .glassCard()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "text.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                Text("Bu ev için henüz yorum eklenmedi.")
                                    .font(.subheadline)
                                    .foregroundStyle(AstroTheme.textTertiary)
                            }
                            .padding(.top, 40)
                        }

                        // Evdeki gezegenler
                        if !house.planets.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Bu Evdeki Gezegenler")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                ForEach(house.planets) { planet in
                                    HStack(spacing: 10) {
                                        Text(planet.sign.glyph)
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(planet.planet.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.white)
                                            Text("\(planet.sign.name) \(String(format: "%.1f°", planet.degree))")
                                                .font(.caption)
                                                .foregroundStyle(AstroTheme.textSecondary)
                                        }
                                        Spacer()
                                        if planet.isRetrograde {
                                            Text("℞")
                                                .font(.caption.bold())
                                                .foregroundStyle(.red)
                                        }
                                    }
                                }
                            }
                            .glassCard()
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("\(house.id). Ev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }
}
