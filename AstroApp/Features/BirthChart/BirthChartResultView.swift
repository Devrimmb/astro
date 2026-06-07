import SwiftUI

struct BirthChartResultView: View {
    @Environment(AppState.self) private var appState
    let chart: BirthChart
    let personName: String
    @State private var selectedHouse: House?
    @State private var selectedPlanet: PlanetPosition?
    @State private var selectedAspect: SelectedAspectItem?
    @State private var showAspectGrid = false
    @State private var expandedElements: Set<ZodiacSign.Element> = []

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    personHeaderBar
                    chartWheelCard
                    bigThreeCard
                    if let expr = chart.dominantSignExpression { dominantSignCard(expr) }
                    elementInterpretationCard
                    modalityCard
                    planetPositionsCard
                    housesCard
                    aspectsCard

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

    // MARK: - Kişi Başlık Çubuğu

    private var personHeaderBar: some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        dateFormatter.locale = Locale(identifier: "tr_TR")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let dateStr = dateFormatter.string(from: chart.birthDate)
        let timeStr = timeFormatter.string(from: chart.birthDate)

        return HStack(spacing: 6) {
            Text(personName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("·")
                .foregroundStyle(AstroTheme.textTertiary)
            Text(dateStr)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
            Text("·")
                .foregroundStyle(AstroTheme.textTertiary)
            Text(timeStr)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .glassCard()
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

    // MARK: - Burç Yansıması

    private func dominantSignCard(_ expr: BirthChart.DominantSignExpression) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 3) {
                let elemColor = elementColor(expr.element)
                (Text(expr.element.displayName).foregroundStyle(elemColor).bold()
                + Text(" elementiniz baskın ve ").foregroundStyle(.white)
                + Text(expr.sign.name).foregroundStyle(elemColor).bold()
                + Text(" burcu özelliği yansıtıyorsunuz.").foregroundStyle(.white))
                .font(.subheadline.weight(.medium))
                .lineSpacing(2)
                Text("\(expr.sign.glyph) \(expr.sign.name) · \(expr.element.displayName)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            Spacer()
        }
        .glassCard()
    }

    // MARK: - Modalite Dengesi

    private var modalityCard: some View {
        let modalities = chart.modalityBalance

        return VStack(spacing: 14) {
            Text("Modalite Dengesi")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                ForEach(ZodiacSign.Modality.allCases, id: \.self) { modality in
                    let count = modalities[modality, default: 0]

                    VStack(spacing: 6) {
                        Image(systemName: modalityIcon(modality))
                            .font(.title3)
                            .foregroundStyle(modalityColor(modality))
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
        let totalScore = elements.values.reduce(0, +)

        let sortedElements = ZodiacSign.Element.allCases.sorted {
            (elements[$0, default: 0]) > (elements[$1, default: 0])
        }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Element Yorumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(sortedElements, id: \.self) { element in
                let score = elements[element, default: 0]
                let ratio = totalScore > 0 ? score / totalScore : 0
                let status = ElementInterpretation.status(score: score, totalScore: totalScore)
                let isExpanded = expandedElements.contains(element)

                if let entry = ElementInterpretation.entry(for: element) {
                    let statusText: String = switch status {
                    case .more:    entry.more
                    case .less:    entry.less
                    case .limited: entry.limited
                    case .balance: entry.balance
                    }

                    let statusColor: Color = switch status {
                    case .more:    elementColor(element)
                    case .less:    AstroTheme.textTertiary
                    case .limited: .orange
                    case .balance: .green
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        // — Kapalı satır (her zaman görünür) —
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if isExpanded {
                                    expandedElements.remove(element)
                                } else {
                                    expandedElements.insert(element)
                                }
                            }
                        } label: {
                            VStack(spacing: 8) {
                                HStack(spacing: 10) {
                                    Image(systemName: elementIcon(element))
                                        .font(.title3)
                                        .foregroundStyle(elementColor(element))
                                        .frame(width: 28)

                                    Text(element.displayName)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Text("%\(Int((ratio * 100).rounded()))")
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(elementColor(element))

                                    HStack(spacing: 3) {
                                        Image(systemName: status.icon)
                                            .font(.caption2)
                                        Text(status.displayName)
                                            .font(.caption.weight(.semibold))
                                    }
                                    .foregroundStyle(statusColor)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(statusColor.opacity(0.12), in: .capsule)

                                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption2)
                                        .foregroundStyle(AstroTheme.textTertiary)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(.white.opacity(0.08))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(elementColor(element))
                                            .frame(width: geo.size.width * ratio)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(12)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)

                        // — Açılır yorum bölümü —
                        if isExpanded {
                            elementExpandedContent(
                                entry: entry,
                                status: status,
                                statusText: statusText,
                                statusColor: statusColor
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                (status == .balance || status == .limited) ? AstroTheme.cardBorder : statusColor.opacity(0.3),
                                lineWidth: 1
                            )
                    }
                    .clipped()
                }
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func elementExpandedContent(
        entry: ElementEntry,
        status: ElementInterpretation.ElementStatus,
        statusText: String,
        statusColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            dividerLine

            // Element açıklaması
            Text("\(entry.name) elementi \(entry.description)")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .lineSpacing(3)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            dividerLine

            // Durum metni
            Text(statusText)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .lineSpacing(3)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            // Renk / Taş / Koku desteği
            if let support = entry.support(for: status) {
                VStack(alignment: .leading, spacing: 6) {
                    dividerLine.padding(.top, 8)

                    if let colors = support.colors {
                        supportRow(icon: "paintpalette.fill", label: "Renkler", value: colors, color: statusColor)
                    }
                    if let stones = support.stones, !stones.isEmpty {
                        supportListRow(icon: "sparkle", label: "Faydalı Taşlar", items: stones, color: statusColor)
                    }
                    if let scents = support.scents, !scents.isEmpty {
                        supportListRow(icon: "wind", label: "Aromatik Kokular", items: scents, color: statusColor)
                    }
                }
            }

            Spacer(minLength: 12)
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private func supportRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color.opacity(0.8))
                .frame(width: 14)
            Text(label + ":")
                .font(.caption2.bold())
                .foregroundStyle(color.opacity(0.9))
            Text(value)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .padding(.horizontal, 12)
    }

    private func supportListRow(icon: String, label: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color.opacity(0.8))
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(color.opacity(0.9))
            }
            .padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(color.opacity(0.6))
                        Text(item)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func formatScore(_ score: Double) -> String {
        score.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(score))" : String(format: "%.1f", score)
    }

    private func elementIcon(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:  "flame.fill"
        case .earth: "leaf.fill"
        case .air:   "wind"
        case .water: "drop.fill"
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
        case .cardinal: "bolt.fill"
        case .fixed:    "circle.fill"
        case .mutable:  "arrow.triangle.2.circlepath"
        }
    }

    private func modalityColor(_ modality: ZodiacSign.Modality) -> Color {
        switch modality {
        case .cardinal: .yellow
        case .fixed:    .purple
        case .mutable:  .cyan
        }
    }

    @ViewBuilder
    private func aspectPointLabel(_ point: ChartPoint) -> some View {
        let glyph = point.glyph
        let isSingleGlyph = glyph.count == 1
        HStack(spacing: isSingleGlyph ? 3 : 0) {
            if isSingleGlyph {
                Text(glyph)
                    .foregroundStyle(chartPointColor(point))
                    .frame(width: 14)
            }
            Text(point.name)
                .frame(width: isSingleGlyph ? 50 : 65, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.caption)
        .frame(width: 65, alignment: .leading)
    }

    private func chartPointColor(_ point: ChartPoint) -> Color {
        switch point {
        case .planet(let p):
            switch p {
            case .sun:          .orange
            case .moon:         .white
            case .mercury:      .cyan
            case .venus:        .pink
            case .mars:         .red
            case .jupiter:      .purple
            case .saturn:       .brown
            case .uranus:       .teal
            case .neptune:      .indigo
            case .pluto:        .gray
            case .northNode:    .mint
            case .chiron:       .yellow
            case .lilith:       Color(red: 0.7, green: 0.3, blue: 0.9)
            case .partOfFortune: .green
            case .ceres:        Color(red: 0.6, green: 0.4, blue: 0.2)
            case .pallas:       Color(red: 0.5, green: 0.7, blue: 0.9)
            case .juno:         Color(red: 0.8, green: 0.4, blue: 0.6)
            case .vesta:        Color(red: 0.9, green: 0.5, blue: 0.2)
            }
        case .ascendant: .orange
        case .midheaven: .orange
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
                if !showAspectGrid {
                    Text("Dokun → Yorum")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
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
                    Button {
                        selectedAspect = SelectedAspectItem(
                            aspect: aspect,
                            interpretation: appState.interpretation.aspectInterpretation(aspect)
                        )
                    } label: {
                        HStack {
                            aspectPointLabel(aspect.point1)
                            Text(aspect.type.symbol)
                                .font(.caption)
                            aspectPointLabel(aspect.point2)
                            Spacer()
                            Text(String(format: "%.1f°", aspect.orb))
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                            Circle()
                                .fill(aspectNatureColor(aspect.type.nature))
                                .frame(width: 6, height: 6)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(aspect.point1.name) \(aspect.type.turkishName) \(aspect.point2.name), orb \(String(format: "%.1f", aspect.orb)) derece. Yorum için dokun.")
                }
            }
        }
        .glassCard()
        .sheet(item: $selectedAspect) { item in
            AspectInterpretationSheet(
                aspect: item.aspect,
                interpretation: item.interpretation
            )
        }
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

private struct SelectedAspectItem: Identifiable {
    let id = UUID()
    let aspect: Aspect
    let interpretation: Interpretation?
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

// MARK: - Açı Yorum Sheet

private struct AspectInterpretationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let aspect: Aspect
    let interpretation: Interpretation?

    private var aspectTitle: String {
        "\(aspect.point1.name) \(aspect.type.symbol) \(aspect.point2.name)"
    }

    private var missingMessage: String {
        if !aspect.type.isMajor {
            return "Bu açı türü için henüz yorum eklenmedi."
        }
        return "Bu açı için henüz yorum eklenmedi."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AstroTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(aspect.type.symbol)
                                .font(.system(size: 48))
                                .foregroundStyle(.white)
                            Text(aspectTitle)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            HStack(spacing: 6) {
                                Text(aspect.type.turkishName)
                                Text("·")
                                Text("Orb \(String(format: "%.1f°", aspect.orb))")
                                Text("·")
                                Text(aspect.applying ? "Uygulayan" : "Ayrılan")
                            }
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                        }
                        .padding(.top, 8)

                        if let interpretation {
                            VStack(alignment: .leading, spacing: 12) {
                                MarkdownTextView(interpretation.detailed)
                            }
                            .glassCard()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "text.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                Text(missingMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(AstroTheme.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Açı Yorumu")
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
