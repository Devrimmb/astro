import SwiftUI

struct CompositeChartView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedPerson1: BirthData?
    @State private var selectedPerson2: BirthData?
    @State private var compositeChart: CompositeChart?
    @State private var isLoading = false

    // Sonuç sayfasına geçiş
    @State private var showResult = false
    @State private var resultName1 = ""
    @State private var resultName2 = ""

    // Manuel giriş fallback
    @State private var useManualEntry = false
    @State private var person1Name = ""
    @State private var person1BirthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 12))!
    @State private var person1CountryCode = "TR"
    @State private var person1City = "İstanbul"
    @State private var person2Name = ""
    @State private var person2BirthDate = Date(timeIntervalSince1970: 757_382_400)
    @State private var person2CountryCode = "TR"
    @State private var person2City = "İstanbul"

    private var hasSavedPeople: Bool {
        appState.birthDataStore.people.count >= 2
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    introCard

                    if hasSavedPeople && !useManualEntry {
                        peoplePickerCard
                    } else {
                        manualInputCard
                    }

                    if hasSavedPeople {
                        toggleModeButton
                    }

                    if isLoading {
                        ProgressView("Hesaplanıyor...")
                            .tint(AstroTheme.accent)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 20)
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Composite Harita")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showResult) {
            if let composite = compositeChart {
                CompositeChartResultView(
                    composite: composite,
                    name1: resultName1,
                    name2: resultName2
                )
            }
        }
        .onAppear {
            if selectedPerson1 == nil {
                selectedPerson1 = appState.birthDataStore.ownerPerson
            }
            if selectedPerson2 == nil {
                selectedPerson2 = appState.birthDataStore.people.first(where: { !$0.isOwner })
            }
        }
    }

    // MARK: - Intro

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.merge")
                    .font(.title2)
                    .foregroundStyle(.mint)
                Text("Composite Harita")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text("İki kişinin haritasının orta noktalarından oluşan, ilişkinizi kendi başına bir varlık olarak gösteren harita. İki kişiyi seçip hesaplayın.")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - People Picker

    private var peoplePickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kişileri Seçin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("1. Kişi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
                personPicker(selection: $selectedPerson1, exclude: selectedPerson2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("2. Kişi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
                personPicker(selection: $selectedPerson2, exclude: selectedPerson1)
            }

            Button {
                Task { await calculateFromPeople() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.merge")
                    Text("Composite Hesapla")
                }
                .glassButton()
            }
            .disabled(selectedPerson1 == nil || selectedPerson2 == nil)
        }
        .glassCard()
    }

    private func personPicker(selection: Binding<BirthData?>, exclude: BirthData?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(appState.birthDataStore.people) { person in
                    if person.id != exclude?.id {
                        let isSelected = selection.wrappedValue?.id == person.id
                        Button {
                            selection.wrappedValue = person
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: person.isOwner ? "person.fill" : "person")
                                    .font(.caption)
                                Text(person.name.isEmpty ? "İsimsiz" : person.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(isSelected ? .white : AstroTheme.textSecondary)
                            .frame(width: 72, height: 52)
                            .background(
                                isSelected
                                    ? AnyShapeStyle(AstroTheme.accent.opacity(0.3))
                                    : AnyShapeStyle(AstroTheme.surface),
                                in: .rect(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? AstroTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Manuel Giriş

    private var manualInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundStyle(AstroTheme.accent)
                Text("Bilgileri Girin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            personInputFields(label: "1. Kişi", name: $person1Name, date: $person1BirthDate, countryCode: $person1CountryCode, city: $person1City)
            Divider().overlay(AstroTheme.cardBorder)
            personInputFields(label: "2. Kişi", name: $person2Name, date: $person2BirthDate, countryCode: $person2CountryCode, city: $person2City)

            Button {
                Task { await calculateFromManual() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.merge")
                    Text("Composite Hesapla")
                }
                .glassButton()
            }
        }
        .glassCard()
    }

    private func personInputFields(label: String, name: Binding<String>, date: Binding<Date>, countryCode: Binding<String>, city: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(AstroTheme.accent)

            TextField("İsim", text: name)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(10)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 10))

            DatePicker("Doğum Tarihi", selection: date, displayedComponents: [.date, .hourAndMinute])
                .font(.subheadline)
                .foregroundStyle(.white)
                .colorScheme(.dark)

            LocationPickerView(
                selectedCountryCode: countryCode,
                selectedCity: city
            )
        }
    }

    // MARK: - Toggle Mode

    private var toggleModeButton: some View {
        Button {
            useManualEntry.toggle()
            compositeChart = nil
        } label: {
            HStack(spacing: 6) {
                Image(systemName: useManualEntry ? "person.2" : "keyboard")
                    .font(.caption2)
                Text(useManualEntry ? "Kayıtlı kişilerden seç" : "Manuel giriş yap")
                    .font(.caption)
            }
            .foregroundStyle(AstroTheme.textSecondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(AstroTheme.surface, in: .capsule)
        }
    }

    // MARK: - Calculation

    private func calculateFromPeople() async {
        guard let p1 = selectedPerson1, let p2 = selectedPerson2 else { return }
        isLoading = true
        let coords1 = WorldCityStore.coordinates(for: p1.cityName, countryCode: "")
        let coords2 = WorldCityStore.coordinates(for: p2.cityName, countryCode: "")
        let tz1 = TimeZone(identifier: coords1.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        let tz2 = TimeZone(identifier: coords2.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        async let chart1 = appState.ephemeris.calculateBirthChart(
            date: p1.birthDate, latitude: p1.latitude, longitude: p1.longitude,
            timeZone: tz1
        )
        async let chart2 = appState.ephemeris.calculateBirthChart(
            date: p2.birthDate, latitude: p2.latitude, longitude: p2.longitude,
            timeZone: tz2
        )
        let result = CompositeChartCalculator.calculate(chart1: await chart1, chart2: await chart2)
        compositeChart = result
        resultName1 = p1.name.isEmpty ? "Kişi 1" : p1.name
        resultName2 = p2.name.isEmpty ? "Kişi 2" : p2.name
        isLoading = false
        showResult = true
    }

    private func calculateFromManual() async {
        let coords1 = WorldCityStore.coordinates(for: person1City, countryCode: person1CountryCode)
        let coords2 = WorldCityStore.coordinates(for: person2City, countryCode: person2CountryCode)
        isLoading = true
        let tz1 = TimeZone(identifier: coords1.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        let tz2 = TimeZone(identifier: coords2.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        async let chart1 = appState.ephemeris.calculateBirthChart(
            date: person1BirthDate, latitude: coords1.lat, longitude: coords1.lon,
            timeZone: tz1
        )
        async let chart2 = appState.ephemeris.calculateBirthChart(
            date: person2BirthDate, latitude: coords2.lat, longitude: coords2.lon,
            timeZone: tz2
        )
        let result = CompositeChartCalculator.calculate(chart1: await chart1, chart2: await chart2)
        compositeChart = result
        resultName1 = person1Name.isEmpty ? "Kişi 1" : person1Name
        resultName2 = person2Name.isEmpty ? "Kişi 2" : person2Name
        isLoading = false
        showResult = true
    }
}

// MARK: - Sonuç Sayfası

struct CompositeChartResultView: View {
    let composite: CompositeChart
    let name1: String
    let name2: String

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    coupleHeader

                    ChartWheelView(chart: composite.asBirthChart, size: 340)
                        .glassCard()
                    bigThreeCard(composite)
                    elementBalanceCard(composite)
                    planetsCard(composite)
                    aspectsCard(composite)
                    interpretationsCard(composite)

                    // Paylaş
                    Button {
                        ShareImageRenderer.shareComposite(
                            person1Name: name1,
                            person2Name: name2,
                            composite: composite
                        )
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Paylaş")
                        }
                        .glassButton()
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Composite Harita")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Çift Başlığı

    private var coupleHeader: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(name1)
                    .font(.headline)
                    .foregroundStyle(.white)
                Image(systemName: "arrow.triangle.merge")
                    .font(.caption)
                    .foregroundStyle(.mint)
                Text(name2)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Text("İlişki Haritası")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Result Cards

    private func bigThreeCard(_ chart: CompositeChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Composite Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                threeItem(title: "Güneş", sign: chart.sunSign, color: .orange)
                threeItem(title: "Ay", sign: chart.moonSign, color: .cyan)
                threeItem(title: "Yükselen", sign: chart.ascendant, color: AstroTheme.accent)
            }

            Text("Composite harita, ilişkinizin kendi başına bir varlık olarak enerjisini gösterir.")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .glassCard()
    }

    private func threeItem(title: String, sign: ZodiacSign?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(sign?.glyph ?? "?")
                .font(.title2)
            Text(sign?.name ?? "—")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func planetsCard(_ chart: CompositeChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gezegen Konumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(chart.planets, id: \.planet) { pos in
                HStack(spacing: 8) {
                    Text(pos.planet.rawValue)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .frame(width: 70, alignment: .leading)
                    Text(pos.sign.glyph)
                        .font(.caption)
                    Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(pos.house). ev")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                if pos.planet != chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    private func aspectsCard(_ chart: CompositeChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Açılar (\(chart.aspects.count))")
                .font(.headline)
                .foregroundStyle(.white)

            let shown = Array(chart.aspects.prefix(15).enumerated())
            ForEach(shown, id: \.offset) { index, aspect in
                HStack(spacing: 6) {
                    Text(aspect.point1.name)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    Text(aspect.type.symbol)
                        .font(.caption2)
                        .foregroundStyle(aspectColor(aspect.type))
                    Text(aspect.point2.name)
                        .font(.caption2)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(aspect.type.turkishName)
                        .font(.caption2)
                        .foregroundStyle(aspectColor(aspect.type))
                }
                .padding(.vertical, 3)
                if index != shown.count - 1 {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yorumlar (bütüncül sentez)

    private func interpretationsCard(_ chart: CompositeChart) -> some View {
        let majors = chart.aspects.filter { $0.type.isMajor }
        let guidances = majors.map { asp in
            ChartSynthesizer.WeightedGuidance(
                item: ChartAspectInterpreter.interpretation(asp, context: .composite),
                weight: ChartSynthesizer.weight(asp),
                planets: ChartSynthesizer.planets(in: asp)
            )
        }
        let synth = ChartSynthesizer.synthesize(
            guidances,
            structure: ChartSynthesizer.ChartStructure(planets: chart.planets, aspects: chart.aspects),
            context: .composite
        )
        return ChartSynthesisSection(synthesis: synth)
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type.nature {
        case .harmonik: AstroTheme.harmonik
        case .zorlayici: AstroTheme.zorlayici
        case .notr: AstroTheme.accent
        }
    }

    // MARK: - Element Dengesi

    private func elementBalanceCard(_ chart: CompositeChart) -> some View {
        let balance = chart.asBirthChart.elementBalance
        let total = balance.values.reduce(0, +)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "circle.grid.2x2.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Element Dengesi")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                let value = balance[element] ?? 0
                let pct = total > 0 ? value / total : 0
                HStack(spacing: 8) {
                    Image(systemName: elementIcon(element))
                        .font(.caption)
                        .foregroundStyle(elementColor(element))
                        .frame(width: 16)
                    Text(element.displayName)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 52, alignment: .leading)
                    ProgressView(value: pct)
                        .tint(elementColor(element))
                        .frame(maxWidth: .infinity)
                    Text("\(Int(pct * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(elementColor(element))
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .glassCard()
    }

    private func elementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire:  .red
        case .earth: .green
        case .air:   .yellow
        case .water: .blue
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
}
