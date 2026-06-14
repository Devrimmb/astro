import SwiftUI

struct SolarReturnView: View {
    @Environment(AppState.self) private var appState
    @State private var natalChart: BirthChart?
    @State private var personName = ""

    // Solar Return
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var solarReturn: SolarReturn?
    @State private var isLoading = false

    // Ay Dönüşü
    @State private var lunarReturn: LunarReturn?
    @State private var lunarFromDate: Date = .now
    @State private var isLoadingLunar = false

    // Mod seçimi
    @State private var showingLunarReturn = false

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 2)...(currentYear + 5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                if natalChart == nil {
                    personSelectionView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            modePicker

                            if !showingLunarReturn {
                                // ── Güneş Dönüşü ──
                                yearSelector
                                if isLoading {
                                    ProgressView("Hesaplanıyor...")
                                        .tint(AstroTheme.accent)
                                        .foregroundStyle(AstroTheme.textSecondary)
                                        .padding(.top, 40)
                                } else if let sr = solarReturn {
                                    returnDateCard(sr)
                                    // SR vs Natal bi-wheel
                                    if let natal = natalChart {
                                        srBiWheelCard(natal: natal, sr: sr)
                                    }
                                    returnBigThreeCard(sr)
                                    returnAspectsCard(sr)
                                    srInterpretations(sr)
                                    returnPlanetsCard(sr)

                                    Button {
                                        ShareImageRenderer.shareSolarReturn(
                                            personName: personName,
                                            solarReturn: sr
                                        )
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.arrow.up")
                                            Text("Paylaş")
                                        }
                                        .glassButton()
                                    }
                                }
                            } else {
                                // ── Ay Dönüşü ──
                                lunarNavCard
                                if isLoadingLunar {
                                    ProgressView("Hesaplanıyor...")
                                        .tint(AstroTheme.accent)
                                        .foregroundStyle(AstroTheme.textSecondary)
                                        .padding(.top, 40)
                                } else if let lr = lunarReturn {
                                    lunarDateCard(lr)
                                    ChartWheelView(chart: lr.chart, size: 340)
                                        .glassCard()
                                    lunarBigThreeCard(lr)
                                    lunarPlanetsCard(lr)
                                }
                            }

                            Button {
                                natalChart = nil
                                solarReturn = nil
                                lunarReturn = nil
                            } label: {
                                Label("Farklı Kişi Seç", systemImage: "person.2")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AstroTheme.textSecondary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(AstroTheme.surface, in: .capsule)
                                    .overlay { Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1) }
                            }
                        }
                        .padding()
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(showingLunarReturn ? "Ay Dönüşü" : "Güneş Dönüşü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedYear) { Task { await loadSolarReturn() } }
            .onChange(of: showingLunarReturn) { newVal in
                if newVal && lunarReturn == nil { Task { await loadLunarReturn() } }
            }
        }
    }

    // MARK: - Mod Seçici

    private var modePicker: some View {
        Picker("", selection: $showingLunarReturn) {
            Text("☀️ Güneş Dönüşü").tag(false)
            Text("🌙 Ay Dönüşü").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 4)
    }

    // MARK: - Kişi Seçimi

    private var personSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Güneş & Ay Dönüşü")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Yıllık Solar ve aylık Lunar Return haritaları")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                PersonSelectionCard(
                    title: "Kişi Seçin",
                    buttonTitle: "Hesapla",
                    buttonIcon: "sun.max.circle"
                ) { birthData in
                    Task { await calculateForPerson(birthData) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                    } label: {
                        Text(String(year))
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedYear == year ? .white : AstroTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedYear == year
                                    ? AnyShapeStyle(AstroTheme.accentGradient.opacity(0.5))
                                    : AnyShapeStyle(AstroTheme.surface),
                                in: .capsule
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedYear == year ? AstroTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Ay Dönüşü Navigasyon

    private var lunarNavCard: some View {
        HStack {
            Button {
                if let current = lunarReturn {
                    lunarFromDate = current.exactDate.addingTimeInterval(-29 * 24 * 3600)
                } else {
                    lunarFromDate = lunarFromDate.addingTimeInterval(-29 * 24 * 3600)
                }
                Task { await loadLunarReturn() }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AstroTheme.accent)
                    .padding(.horizontal, 8)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Ay Dönüşü")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                if let lr = lunarReturn {
                    Text(lr.dateText)
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                } else {
                    Text(monthYearText(lunarFromDate))
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }

            Spacer()

            Button {
                if let current = lunarReturn {
                    lunarFromDate = current.exactDate.addingTimeInterval(3600)
                } else {
                    lunarFromDate = lunarFromDate.addingTimeInterval(27 * 24 * 3600)
                }
                Task { await loadLunarReturn() }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AstroTheme.accent)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 8)
        .glassCard()
    }

    // MARK: - SR Bi-Wheel (SR vs Natal)

    private func srBiWheelCard(natal: BirthChart, sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(.orange)
                Text("SR & Natal Karşılaştırma")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            HStack {
                Label("Natal", systemImage: "person.fill")
                    .font(.caption2).foregroundStyle(.white)
                Text("(iç halka)").font(.caption2).foregroundStyle(AstroTheme.textTertiary)
                Spacer()
                Label("SR \(sr.year)", systemImage: "sun.max")
                    .font(.caption2).foregroundStyle(.white.opacity(0.7))
                Text("(dış halka)").font(.caption2).foregroundStyle(AstroTheme.textTertiary)
            }
            TransitBiWheelView(
                natalChart: natal,
                transitPositions: sr.chart.planets,
                size: 320
            )
            .frame(maxWidth: .infinity)
        }
        .glassCard()
    }

    // MARK: - Solar Return Kartları

    private func returnDateCard(_ sr: SolarReturn) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("\(String(sr.year)) Güneş Dönüşü")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(sr.dateText)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)

            Text("Güneş natal konumuna geri dönüyor — yeni bir yıllık döngü başlıyor.")
                .font(.caption)
                .foregroundStyle(AstroTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .glassCard()
    }

    private func returnBigThreeCard(_ sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yıllık Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                bigThreeItem(title: "SR Yükselen", sign: sr.returnAscendant,   color: AstroTheme.accent, description: "Yılın genel tonu")
                bigThreeItem(title: "SR Ay",       sign: sr.returnMoonSign,     color: .cyan,             description: "Duygusal tema")
                bigThreeItem(title: "SR Güneş",    sign: sr.chart.sunSign,      color: .orange,           description: "Temel enerji")
            }
        }
        .glassCard()
    }

    private func returnAspectsCard(_ sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lines.measurement.horizontal")
                    .foregroundStyle(AstroTheme.accent)
                Text("SR Açıları (\(sr.chart.aspects.count))")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if sr.chart.aspects.isEmpty {
                Text("Bu haritada hesaplanmış açı bulunmuyor.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                let shown = Array(sr.chart.aspects.prefix(12).enumerated())
                ForEach(shown, id: \.offset) { index, aspect in
                    srAspectRow(aspect)
                    if index != shown.count - 1 {
                        Divider().overlay(AstroTheme.cardBorder)
                    }
                }
            }
        }
        .glassCard()
    }

    private func srAspectRow(_ aspect: Aspect) -> some View {
        HStack(spacing: 6) {
            Text(aspect.point1.name)
                .font(.caption2).foregroundStyle(.white)
            Text(aspect.type.symbol)
                .font(.caption2).foregroundStyle(srAspectColor(aspect.type))
            Text(aspect.point2.name)
                .font(.caption2).foregroundStyle(.white)
            Spacer()
            Text(aspect.type.turkishName)
                .font(.caption2).foregroundStyle(srAspectColor(aspect.type))
        }
        .padding(.vertical, 3)
    }

    // MARK: - Bütüncül Yorum (sentez)

    private func srInterpretations(_ sr: SolarReturn) -> some View {
        let majors = sr.chart.aspects.filter { $0.type.isMajor }
        let guidances = majors.map { asp in
            ChartSynthesizer.WeightedGuidance(
                item: ChartAspectInterpreter.interpretation(asp, context: .solarReturn),
                weight: ChartSynthesizer.weight(asp),
                planets: ChartSynthesizer.planets(in: asp)
            )
        }
        let synth = ChartSynthesizer.synthesize(
            guidances,
            structure: ChartSynthesizer.ChartStructure(planets: sr.chart.planets, aspects: sr.chart.aspects),
            context: .solarReturn
        )
        return ChartSynthesisSection(synthesis: synth)
    }

    private func returnPlanetsCard(_ sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gezegen Konumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(sr.chart.planets, id: \.planet) { pos in
                HStack(spacing: 8) {
                    Text(pos.planet.rawValue)
                        .font(.caption).foregroundStyle(AstroTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    Text(pos.sign.glyph).font(.caption)
                    Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                        .font(.caption.bold()).foregroundStyle(.white)
                    Spacer()
                    Text("\(pos.house). ev")
                        .font(.caption2).foregroundStyle(AstroTheme.textTertiary)
                    if pos.isRetrograde {
                        Text("℞").font(.caption2).foregroundStyle(.red)
                    }
                }
                if pos.planet != sr.chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Ay Dönüşü Kartları

    private func lunarDateCard(_ lr: LunarReturn) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.cyan)

            Text("Ay Dönüşü")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(lr.dateText)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)

            Text("Ay natal konumuna geri dönüyor — yeni bir aylık döngü başlıyor.")
                .font(.caption)
                .foregroundStyle(AstroTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .glassCard()
    }

    private func lunarBigThreeCard(_ lr: LunarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Aylık Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                bigThreeItem(title: "LR Yükselen", sign: lr.chart.ascendant, color: AstroTheme.accent, description: "Ayın tonu")
                bigThreeItem(title: "LR Güneş",   sign: lr.chart.sunSign,   color: .orange,           description: "Aktif enerji")
                bigThreeItem(title: "LR Ay",       sign: lr.chart.moonSign,  color: .cyan,             description: "Duygusal tema")
            }
        }
        .glassCard()
    }

    private func lunarPlanetsCard(_ lr: LunarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gezegen Konumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(lr.chart.planets, id: \.planet) { pos in
                HStack(spacing: 8) {
                    Text(pos.planet.rawValue)
                        .font(.caption).foregroundStyle(AstroTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    Text(pos.sign.glyph).font(.caption)
                    Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                        .font(.caption.bold()).foregroundStyle(.white)
                    Spacer()
                    Text("\(pos.house). ev")
                        .font(.caption2).foregroundStyle(AstroTheme.textTertiary)
                    if pos.isRetrograde {
                        Text("℞").font(.caption2).foregroundStyle(.red)
                    }
                }
                if pos.planet != lr.chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Ortak Yardımcılar

    private func bigThreeItem(title: String, sign: ZodiacSign?, color: Color, description: String) -> some View {
        VStack(spacing: 4) {
            Text(sign?.glyph ?? "?").font(.title2)
            Text(sign?.name ?? "—").font(.caption.bold()).foregroundStyle(color)
            Text(title).font(.caption2).foregroundStyle(AstroTheme.textSecondary)
            Text(description).font(.caption2).foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func srAspectColor(_ type: AspectType) -> Color {
        switch type.nature {
        case .harmonik:  AstroTheme.harmonik
        case .zorlayici: AstroTheme.zorlayici
        case .notr:      AstroTheme.accent
        }
    }

    private func monthYearText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Data Loading

    private func calculateForPerson(_ data: BirthData) async {
        personName = data.name
        isLoading = true
        let coords = WorldCityStore.coordinates(for: data.cityName, countryCode: "")
        let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        let chart = await appState.ephemeris.calculateBirthChart(
            date: data.birthDate,
            latitude: data.latitude,
            longitude: data.longitude,
            timeZone: tz
        )
        natalChart = chart
        await loadSolarReturn()
    }

    private func loadSolarReturn() async {
        guard let chart = natalChart else { return }
        isLoading = true
        solarReturn = await appState.ephemeris.calculateSolarReturn(
            natalChart: chart,
            year: selectedYear,
            latitude: chart.latitude,
            longitude: chart.longitude,
            timeZone: chart.timeZone
        )
        isLoading = false
    }

    private func loadLunarReturn() async {
        guard let chart = natalChart else { return }
        isLoadingLunar = true
        lunarReturn = await appState.ephemeris.calculateLunarReturn(
            natalChart: chart,
            fromDate: lunarFromDate,
            latitude: chart.latitude,
            longitude: chart.longitude,
            timeZone: chart.timeZone
        )
        isLoadingLunar = false
    }
}
