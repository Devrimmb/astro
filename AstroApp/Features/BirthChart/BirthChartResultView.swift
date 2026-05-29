import SwiftUI

struct BirthChartResultView: View {
    @Environment(AppState.self) private var appState
    let chart: BirthChart
    let personName: String
    @State private var selectedHouse: House?
    @State private var selectedPlanet: PlanetPosition?
    @State private var showAspectGrid = false

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    chartWheelCard
                    bigThreeCard
                    elementBalanceCard
                    elementInterpretationCard
                    planetPositionsCard
                    housesCard
                    aspectsCard

                    // Aksiyon butonları
                    HStack(spacing: 12) {
                        Button {
                            ShareImageRenderer.shareChart(chart: chart, ownerName: personName)
                            appState.gamification.earn(.shareResult)
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

    // MARK: - Element Yorumları

    private var elementInterpretationCard: some View {
        let elements = chart.elementBalance
        let totalPlanets = chart.planets.count

        // Baskın ve eksik elementleri bul
        let sortedElements = ZodiacSign.Element.allCases.sorted {
            (elements[$0, default: 0]) > (elements[$1, default: 0])
        }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Element Yorumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(sortedElements, id: \.self) { element in
                let count = elements[element, default: 0]
                let status = ElementInterpretation.status(count: count, totalPlanets: totalPlanets)

                if let entry = ElementInterpretation.entry(for: element) {
                    let statusText: String = switch status {
                    case .more: entry.more
                    case .less: entry.less
                    case .balance: entry.balance
                    }

                    let statusColor: Color = switch status {
                    case .more: elementColor(element)
                    case .less: AstroTheme.textTertiary
                    case .balance: .green
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(elementIcon(element))
                                .font(.title3)
                            Text(element.displayName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: status.icon)
                                    .font(.caption)
                                Text(status.displayName)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(statusColor)
                        }

                        // Element tanımı
                        Text("\(entry.name) elementi \(entry.description)")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .lineSpacing(3)

                        Rectangle()
                            .fill(.white.opacity(0.06))
                            .frame(height: 1)

                        // Durum yorumu
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                status == .balance ? AstroTheme.cardBorder : statusColor.opacity(0.3),
                                lineWidth: 1
                            )
                    }
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
            HStack {
                Text("Gezegenler")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Dokun → Yorum")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .padding(.bottom, 4)

            ForEach(chart.planets) { position in
                Button {
                    selectedPlanet = position
                } label: {
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
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(position.planet.name), \(position.sign.name), \(String(format: "%.0f", position.degree)) derece, \(position.house). ev\(position.isRetrograde ? ", retrograd" : ""). Yorum için dokun.")
                if position.planet != chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
        .sheet(item: $selectedPlanet) { position in
            PlanetInterpretationSheet(
                position: position,
                sections: appState.interpretation.interpretations(forPlanet: position.planet, in: chart)
            )
        }
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
            // Başlık + görünüm toggle
            HStack {
                Text("Açılar")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAspectGrid.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showAspectGrid ? "list.bullet" : "grid")
                            .font(.caption2)
                        Text(showAspectGrid ? "Liste" : "Grid")
                            .font(.caption2)
                    }
                    .foregroundStyle(AstroTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AstroTheme.surface, in: .capsule)
                }
            }
            .padding(.bottom, 4)

            if chart.aspects.isEmpty {
                Text("Açı bulunamadı")
                    .foregroundStyle(AstroTheme.textSecondary)
                    .font(.subheadline)
            } else if showAspectGrid {
                // Grid görünümü
                AspectGridView(chart: chart)
            } else {
                // Liste görünümü
                ForEach(Array(chart.aspects.enumerated()), id: \.offset) { _, aspect in
                    HStack {
                        Text(aspect.point1.name)
                            .font(.caption)
                            .frame(width: 65, alignment: .leading)
                        Text(aspect.type.symbol)
                            .font(.caption)
                        Text(aspect.point2.name)
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

    // MARK: - Yardımcılar

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
        case .planetInHouseSign: .purple
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

                                MarkdownTextView(entry.description)
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

// MARK: - Gezegen Yorum Sheet

private struct PlanetInterpretationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let position: PlanetPosition
    let sections: [InterpretationSection]

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Gezegen başlığı
                        VStack(spacing: 8) {
                            Text(position.sign.glyph)
                                .font(.system(size: 48))
                            Text(position.planet.name)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            HStack(spacing: 6) {
                                Text("\(position.sign.name) \(String(format: "%.1f°", position.degree))")
                                Text("·")
                                Text("\(position.house). Ev")
                                if position.isRetrograde {
                                    Text("· ℞")
                                        .foregroundStyle(AstroTheme.zorlayici)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                        }
                        .padding(.top, 8)

                        if sections.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "text.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                Text("Bu gezegen için henüz yorum eklenmedi.")
                                    .font(.subheadline)
                                    .foregroundStyle(AstroTheme.textTertiary)
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(sections) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Text(categoryLabel(section.category))
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(categoryColor(section.category))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(categoryColor(section.category).opacity(0.15), in: .capsule)
                                        Text(section.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                    }
                                    MarkdownTextView(section.body)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glassCard()
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(position.planet.name)
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

    private func categoryLabel(_ category: InterpretationCategory) -> String {
        switch category {
        case .planetInHouseSign: "Ev + Burç"
        case .aspect: "Açı"
        case .bigThree: "Temel"
        case .houseInSign: "Ev Burcu"
        case .element: "Element"
        case .modality: "Modalite"
        }
    }

    private func categoryColor(_ category: InterpretationCategory) -> Color {
        switch category {
        case .planetInHouseSign: .purple
        case .aspect: .orange
        case .bigThree: .orange
        case .houseInSign: .teal
        case .element: AstroTheme.fire
        case .modality: .gray
        }
    }
}
