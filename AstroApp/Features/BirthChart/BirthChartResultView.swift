import SwiftUI

struct BirthChartResultView: View {
    @Environment(AppState.self) private var appState
    let chart: BirthChart
    let personName: String
    @State private var selectedHouse: House?
    @State private var selectedPlanet: PlanetPosition?
    @State private var selectedAspect: SelectedAspectItem?
    @State private var showAllAspects = false
    @State private var expandedElements: Set<ZodiacSign.Element> = []
    @State private var section: ChartSection = .wheel

    /// Sonuç ekranının dört alt görünümü
    private enum ChartSection: String, CaseIterable {
        case wheel = "Harita"
        case planets = "Gezegenler"
        case aspects = "Açılar"
        case reading = "Yorum"
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    personHeaderBar
                    SegmentedGlass(options: ChartSection.allCases, selection: $section) { $0.rawValue }

                    Group {
                        switch section {
                        case .wheel:
                            chartWheelCard
                            bigThreeCard
                        case .planets:
                            planetPositionsCard
                            housesCard
                        case .aspects:
                            aspectsCard
                        case .reading:
                            synthesisSection
                            if let expr = chart.dominantSignExpression { dominantSignCard(expr) }
                            elementInterpretationCard
                            modalityCard
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(section)

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
        .animation(.easeInOut(duration: 0.22), value: section)
        .navigationTitle("Doğum Haritanız")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        // Sheet'ler kökte: hangi segment açık olursa olsun sunulabilsin
        .sheet(item: $selectedPlanet) { position in
            PlanetInterpretationSheet(
                position: position,
                chart: chart,
                sections: appState.interpretation.interpretations(forPlanet: position.planet, in: chart)
            )
        }
        .sheet(item: $selectedHouse) { house in
            HouseInterpretationSheet(house: house)
        }
        .sheet(item: $selectedAspect) { item in
            AspectInterpretationSheet(aspect: item.aspect, interpretation: item.interpretation)
        }
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
            ChartWheelView(chart: chart, size: 340) { position in
                selectedPlanet = position
            }
            Text("Gezegene dokun → yorum")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .glassCard()
    }

    // MARK: - Büyük Üçlü

    private var bigThreeCard: some View {
        VStack(spacing: 14) {
            Text("Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                bigThreeItem(label: "Güneş", sign: chart.sunSign, glyph: "☉", color: AstroTheme.planet(.sun))
                bigThreeItem(label: "Ay", sign: chart.moonSign, glyph: "☽", color: AstroTheme.planet(.moon))
                bigThreeItem(label: "Yükselen", sign: chart.ascendant, glyph: "AC", color: AstroTheme.harmonik)
            }
        }
        .glassCard()
    }

    private func bigThreeItem(label: String, sign: ZodiacSign?, glyph: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(glyph)
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .kerning(1)
                .foregroundStyle(AstroTheme.textTertiary)
            if let sign {
                HStack(spacing: 4) {
                    Text(sign.glyph)
                        .fontDesign(.serif)
                        .foregroundStyle(AstroTheme.element(sign.element))
                    Text(sign.name)
                        .foregroundStyle(.white)
                }
                .font(.caption.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(sign?.name ?? "bilinmiyor")")
    }

    // MARK: - Burç Yansıması

    private func dominantSignCard(_ expr: BirthChart.DominantSignExpression) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.planet(.sun))

            VStack(alignment: .leading, spacing: 3) {
                let elemColor = AstroTheme.element(expr.element)
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
                    case .more:    AstroTheme.element(element)
                    case .less:    AstroTheme.textTertiary
                    case .limited: AstroTheme.zorlayici
                    case .balance: AstroTheme.harmonik
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
                                        .foregroundStyle(AstroTheme.element(element))
                                        .frame(width: 28)

                                    Text(element.displayName)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)

                                    Spacer()

                                    Text("%\(Int((ratio * 100).rounded()))")
                                        .font(.subheadline.weight(.bold).monospacedDigit())
                                        .foregroundStyle(AstroTheme.element(element))

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
                                            .fill(AstroTheme.element(element))
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

    private func elementIcon(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire:  "flame.fill"
        case .earth: "leaf.fill"
        case .air:   "wind"
        case .water: "drop.fill"
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
        case .cardinal: AstroTheme.air
        case .fixed:    AstroTheme.accent
        case .mutable:  AstroTheme.accentSecondary
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
                    HStack(spacing: 6) {
                        PlanetRow(position: position)
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
    }

    // MARK: - Açılar

    /// Majör açılar önem ağırlığına göre (gezegen ağırlığı × dar orb)
    private var strongestAspects: [Aspect] {
        chart.aspects
            .filter { $0.type.isMajor }
            .sorted { ChartSynthesizer.weight($0) > ChartSynthesizer.weight($1) }
            .prefix(5)
            .map { $0 }
    }

    @ViewBuilder
    private var aspectsCard: some View {
        if chart.aspects.isEmpty {
            Text("Açı bulunamadı")
                .foregroundStyle(AstroTheme.textSecondary)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .glassCard()
        } else {
            aspectMatrixCard
            strongestAspectsCard
            allAspectsCard
        }
    }

    private var aspectMatrixCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "triangle")
                    .foregroundStyle(AstroTheme.accent)
                Text("Açı Matrisi")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Pill(text: "\(chart.aspects.count) açı", color: AstroTheme.notr)
            }

            AspectGridView(chart: chart) { aspect in
                selectedAspect = SelectedAspectItem(
                    aspect: aspect,
                    interpretation: appState.interpretation.aspectInterpretation(aspect)
                )
            }

            // Lejant
            HStack(spacing: 12) {
                aspectLegend("△", "Üçgen", .harmonik)
                aspectLegend("⚹", "Altıgen", .harmonik)
                aspectLegend("□", "Kare", .zorlayici)
                aspectLegend("☍", "Karşıt", .zorlayici)
                aspectLegend("☌", "Kavuşum", .notr)
            }
            .padding(.top, 2)

            Text("Hücreye dokun → yorum")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .glassCard()
    }

    private func aspectLegend(_ symbol: String, _ name: String, _ nature: AspectType.Nature) -> some View {
        HStack(spacing: 3) {
            Text(symbol).foregroundStyle(AstroTheme.nature(nature))
            Text(name).foregroundStyle(AstroTheme.textTertiary)
        }
        .font(.caption2)
    }

    private var strongestAspectsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EN GÜÇLÜ AÇILAR")
                .font(.caption2.weight(.bold))
                .kerning(1.2)
                .foregroundStyle(AstroTheme.textTertiary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(strongestAspects.enumerated()), id: \.offset) { index, aspect in
                    let interpretation = appState.interpretation.aspectInterpretation(aspect)
                    Button {
                        selectedAspect = SelectedAspectItem(aspect: aspect, interpretation: interpretation)
                    } label: {
                        HStack(spacing: 6) {
                            AspectRow(aspect, subtitle: interpretation?.short)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }
                        .padding(.vertical, 6)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if index < strongestAspects.count - 1 {
                        Divider().overlay(AstroTheme.cardBorder)
                    }
                }
            }
            .glassCard(padding: 12)
        }
    }

    private var allAspectsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showAllAspects.toggle() }
            } label: {
                HStack {
                    Text("Tüm Açılar")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Pill(text: "\(chart.aspects.count)", color: AstroTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                        .rotationEffect(.degrees(showAllAspects ? 180 : 0))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if showAllAspects {
                ForEach(Array(chart.aspects.enumerated()), id: \.offset) { _, aspect in
                    Button {
                        selectedAspect = SelectedAspectItem(
                            aspect: aspect,
                            interpretation: appState.interpretation.aspectInterpretation(aspect)
                        )
                    } label: {
                        HStack(spacing: 6) {
                            AspectRow(aspect)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(aspect.point1.name) \(aspect.type.turkishName) \(aspect.point2.name), orb \(String(format: "%.1f", aspect.orb)) derece. Yorum için dokun.")
                }
                .transition(.opacity)
            }
        }
        .glassCard()
    }

    // MARK: - Bütüncül Yorum (sentez)

    /// Genel değerlendirme + kalıplar (Büyük Üçgen, T-Kare…) + tona göre gruplar.
    private var synthesisSection: some View {
        let majors = chart.aspects.filter { $0.type.isMajor }
        let guidances = majors.map { asp in
            ChartSynthesizer.WeightedGuidance(
                item: ChartAspectInterpreter.interpretation(asp, context: .natal),
                weight: ChartSynthesizer.weight(asp),
                planets: ChartSynthesizer.planets(in: asp)
            )
        }
        let synth = ChartSynthesizer.synthesize(
            guidances,
            structure: ChartSynthesizer.ChartStructure(planets: chart.planets, aspects: chart.aspects),
            context: .birthChart
        )
        return ChartSynthesisSection(synthesis: synth)
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
                                                .foregroundStyle(AstroTheme.zorlayici)
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
        .astroSheetStyle()
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
        .astroSheetStyle()
    }
}

// MARK: - Gezegen Yorum Sheet

private struct PlanetInterpretationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let position: PlanetPosition
    let chart: BirthChart
    let sections: [InterpretationSection]

    @State private var tab: SheetTab = .reading
    @State private var transits: [TransitAspect]?

    private enum SheetTab: Hashable { case reading, aspects, transits }

    private var planetColor: Color { AstroTheme.planet(position.planet) }

    /// Bu gezegenin haritadaki açıları (dar orb önce)
    private var planetAspects: [Aspect] {
        chart.aspects
            .filter { $0.point1 == .planet(position.planet) || $0.point2 == .planet(position.planet) }
            .sorted { $0.orb < $1.orb }
    }

    private func tabTitle(_ tab: SheetTab) -> String {
        switch tab {
        case .reading:  "Yorum"
        case .aspects:  "Açılar (\(planetAspects.count))"
        case .transits: transits.map { "Transit (\($0.count))" } ?? "Transit"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                SegmentedGlass(options: [.reading, .aspects, .transits], selection: $tab, title: tabTitle)

                Group {
                    switch tab {
                    case .reading:  readingContent
                    case .aspects:  aspectsContent
                    case .transits: transitsContent
                    }
                }
                .id(tab)
                .transition(.opacity)
            }
            .padding()
            .padding(.bottom, 40)
        }
        .animation(.easeInOut(duration: 0.2), value: tab)
        .task {
            // Bugünün gökyüzünün bu natal gezegene yaptığı açılar
            let planet = position.planet
            let natal = chart
            let aspects = await Task.detached(priority: .userInitiated) {
                TransitCalculator.calculate(natalChart: natal, transitDate: .now)
                    .aspects
                    .filter { $0.natalPlanet == planet }
                    .sorted { $0.orb < $1.orb }
            }.value
            transits = aspects
        }
        .astroSheetStyle()
    }

    // MARK: Başlık

    private var header: some View {
        HStack(spacing: 14) {
            Text(position.planet.glyph)
                .font(.system(size: 30, design: .serif))
                .foregroundStyle(planetColor)
                .frame(width: 60, height: 60)
                .background {
                    Circle().fill(
                        RadialGradient(
                            colors: [planetColor.opacity(0.35), planetColor.opacity(0.05)],
                            center: .center, startRadius: 0, endRadius: 30
                        )
                    )
                }
                .shadow(color: planetColor.opacity(0.35), radius: 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(position.planet.name) · \(position.sign.name)")
                    .font(.title2)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text("\(position.house). Ev")
                    Text("·")
                    Text(String(format: "%.1f°", position.degree))
                    Text("·")
                    Text(position.isRetrograde ? "Retro" : "Direkt")
                        .foregroundStyle(position.isRetrograde ? AstroTheme.zorlayici : AstroTheme.textSecondary)
                    Text("·")
                    Text(position.sign.element.displayName)
                        .foregroundStyle(AstroTheme.element(position.sign.element))
                }
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: Yorum

    @ViewBuilder
    private var readingContent: some View {
        if sections.isEmpty {
            emptyNote("Bu gezegen için henüz yorum eklenmedi.")
        } else {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Pill(text: categoryLabel(section.category), color: categoryColor(section.category))
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

    // MARK: Açılar

    @ViewBuilder
    private var aspectsContent: some View {
        if planetAspects.isEmpty {
            emptyNote("\(position.planet.name) haritada belirgin bir açı yapmıyor.")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(planetAspects.enumerated()), id: \.offset) { index, aspect in
                    AspectRow(aspect, subtitle: aspectShort(aspect))
                        .padding(.vertical, 6)
                    if index < planetAspects.count - 1 {
                        Divider().overlay(AstroTheme.cardBorder)
                    }
                }
            }
            .glassCard(padding: 12)
        }
    }

    private func aspectShort(_ aspect: Aspect) -> String {
        ChartAspectInterpreter.interpretation(aspect, context: .natal).message
    }

    // MARK: Transit

    @ViewBuilder
    private var transitsContent: some View {
        if let transits {
            if transits.isEmpty {
                emptyNote("Bugün \(position.planet.name) natal konumuna açı yapan transit yok.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transits.enumerated()), id: \.offset) { index, aspect in
                        VStack(alignment: .leading, spacing: 6) {
                            AspectRow(aspect)
                            Text(DailyCosmicCoach.aspectInterpretation(aspect, today: true).message)
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                        if index < transits.count - 1 {
                            Divider().overlay(AstroTheme.cardBorder)
                        }
                    }
                }
                .glassCard(padding: 12)
            }
        } else {
            HStack {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            }
            .padding(.vertical, 24)
        }
    }

    private func emptyNote(_ text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "text.badge.plus")
                .font(.title2)
                .foregroundStyle(AstroTheme.textTertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
        case .planetInHouseSign: AstroTheme.accent
        case .aspect: AstroTheme.notr
        case .bigThree: AstroTheme.planet(.sun)
        case .houseInSign: AstroTheme.accentSecondary
        case .element: AstroTheme.fire
        case .modality: AstroTheme.textSecondary
        }
    }
}
