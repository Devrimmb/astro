import SwiftUI

struct SynastryView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedPerson1: BirthData?
    @State private var selectedPerson2: BirthData?
    @State private var synastryResult: SynastryResult?
    @State private var isLoading = false

    private var displayName1: String {
        selectedPerson1?.name.isEmpty == false ? selectedPerson1!.name : "1. kişi"
    }

    private var displayName2: String {
        useManualEntry
            ? (partnerName.isEmpty ? "Partner" : partnerName)
            : (selectedPerson2?.name.isEmpty == false ? selectedPerson2!.name : "2. kişi")
    }

    // Manuel giriş fallback
    @State private var useManualEntry = false
    @State private var partnerName = ""
    @State private var partnerBirthDate = Date(timeIntervalSince1970: 757_382_400)
    @State private var partnerCountryCode = "TR"
    @State private var partnerCity = "İstanbul"

    private var hasSavedPeople: Bool {
        appState.birthDataStore.people.count >= 2
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    // Sonuç yokken seçim; sonuç varken seçim kartı gizlenir, çift başlığı gelir
                    if synastryResult == nil || isLoading {
                        if hasSavedPeople && !useManualEntry {
                            peoplePickerCard
                        } else {
                            partnerInputCard
                        }

                        if hasSavedPeople {
                            toggleModeButton
                        }
                    }

                    if isLoading {
                        ProgressView("Harita hesaplanıyor...")
                            .tint(AstroTheme.accent)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 20)
                    } else if let result = synastryResult {
                        pairHeader(result)
                        changePeopleButton
                        relationshipScoreCard(result)
                        scoreCard(result)
                        biWheelCard(result)
                        categoriesCard(result)
                        breakdownCard(result)
                        keyAspectsCard(result)
                        synastryInterpretations(result)
                        synastryShareButton(result)
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Synastry Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if selectedPerson1 == nil {
                selectedPerson1 = appState.birthDataStore.ownerPerson
            }
            if selectedPerson2 == nil {
                selectedPerson2 = appState.birthDataStore.people.first(where: { !$0.isOwner })
            }
        }
    }

    // MARK: - People Picker Card

    private var peoplePickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kişileri Seçin")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Kişi 1
            VStack(alignment: .leading, spacing: 6) {
                Text("1. Kişi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
                personPicker(selection: $selectedPerson1, exclude: selectedPerson2)
            }

            // Kişi 2
            VStack(alignment: .leading, spacing: 6) {
                Text("2. Kişi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
                personPicker(selection: $selectedPerson2, exclude: selectedPerson1)
            }

            // Swap butonu
            HStack {
                Spacer()
                Button {
                    let temp = selectedPerson1
                    selectedPerson1 = selectedPerson2
                    selectedPerson2 = temp
                } label: {
                    Label("Değiştir", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.accent)
                }
                Spacer()
            }

            Button {
                Task { await calculateFromPeople() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                    Text("Synastry Hesapla")
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

    // MARK: - Toggle Mode

    private var toggleModeButton: some View {
        Button {
            useManualEntry.toggle()
            synastryResult = nil
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

    // MARK: - Partner Input (Manuel)

    private var partnerInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(AstroTheme.zorlayici)
                Text("Partner Bilgileri")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            TextField("İsim", text: $partnerName)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(10)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 10))

            DatePicker("Doğum Tarihi", selection: $partnerBirthDate, displayedComponents: [.date, .hourAndMinute])
                .font(.subheadline)
                .foregroundStyle(.white)
                .colorScheme(.dark)

            LocationPickerView(
                selectedCountryCode: $partnerCountryCode,
                selectedCity: $partnerCity
            )

            Button {
                Task { await calculateManual() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                    Text("Synastry Hesapla")
                }
                .glassButton()
            }
        }
        .glassCard()
    }

    // MARK: - Kişileri Değiştir

    /// Sonucu temizler, seçim kartını geri getirir
    private var changePeopleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { synastryResult = nil }
        } label: {
            Label("Kişileri Değiştir", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption.weight(.medium))
                .foregroundStyle(AstroTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AstroTheme.surface, in: .capsule)
                .overlay { Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1) }
        }
    }

    // MARK: - Çift Başlığı

    /// İki kişinin Güneş burcu avatarı ve aralarında ♡ — sonucun kimler için olduğunu bir bakışta söyler.
    private func pairHeader(_ result: SynastryResult) -> some View {
        HStack(spacing: 14) {
            personAvatar(name: displayName1, sign: result.chart1.sunSign, tint: AstroTheme.accent)
            Image(systemName: "heart.fill")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.planet(.venus))
            personAvatar(name: displayName2, sign: result.chart2.sunSign, tint: AstroTheme.accentSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func personAvatar(name: String, sign: ZodiacSign?, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(sign?.glyph ?? "✦")
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(sign.map { AstroTheme.element($0.element) } ?? tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.14), in: .circle)
                .overlay { Circle().stroke(tint.opacity(0.45), lineWidth: 1) }
                .accessibilityHidden(true)
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(width: 90)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(sign?.name ?? "bilinmiyor")")
    }

    // MARK: - Relationship Score Card (Discepolo)

    private func relationshipScoreCard(_ result: SynastryResult) -> some View {
        let rs = result.relationshipScore
        return VStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(AstroTheme.zorlayici)
                Text("İlişki Skoru")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if rs.isDestinySign {
                    Label("Kader İşareti", systemImage: "sparkle")
                        .font(.caption2.bold())
                        .foregroundStyle(AstroTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AstroTheme.accent.opacity(0.15), in: .capsule)
                }
            }

            // Skor gösterimi — Discepolo ölçeği üst sınırsız (30+ nadir), o yüzden halka değil sayı
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("\(rs.scoreValue)")
                        .font(.system(size: 48, design: .serif))
                        .foregroundStyle(discepologColor(rs.scoreValue))
                        .contentTransition(.numericText())
                    Text("PUAN")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(1.2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .frame(minWidth: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text(rs.scoreDescription.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(discepologColor(rs.scoreValue))

                    Text(rs.scoreDescription.turkishDescription)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .lineSpacing(2)
                }
            }

            // Ölçek: 6 bant, içinde bulunulan bant dolu
            discepoloScale(score: rs.scoreValue, color: discepologColor(rs.scoreValue))

            Text("Ciro Discepolo metodu — gezegen etkileşimlerine dayalı")
                .font(.system(size: 9))
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .glassCard(tint: AstroTheme.planet(.venus))
    }

    /// Discepolo bantları: (alt sınır, ad). Son bant açık uçlu.
    private let discepoloBands: [(lower: Int, name: String)] = [
        (0, "Min."), (5, "Orta"), (10, "Önemli"), (15, "Çok Önemli"), (20, "Harika"), (30, "Nadir")
    ]

    private func discepoloScale(score: Int, color: Color) -> some View {
        let activeIndex = discepoloBands.lastIndex { score >= $0.lower } ?? 0
        return VStack(spacing: 5) {
            HStack(spacing: 3) {
                ForEach(Array(discepoloBands.enumerated()), id: \.offset) { index, _ in
                    Capsule()
                        .fill(index <= activeIndex ? color.opacity(index == activeIndex ? 1 : 0.45) : .white.opacity(0.08))
                        .frame(height: 6)
                }
            }
            HStack(spacing: 3) {
                ForEach(Array(discepoloBands.enumerated()), id: \.offset) { index, band in
                    let upper = index + 1 < discepoloBands.count ? "–\(discepoloBands[index + 1].lower)" : "+"
                    VStack(spacing: 1) {
                        Text("\(band.lower)\(upper)")
                        Text(band.name)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(.system(size: 7.5, weight: index == activeIndex ? .bold : .regular))
                    .foregroundStyle(index == activeIndex ? color : AstroTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Discepolo ölçeği: \(score) puan, \(discepoloBands[activeIndex].name)")
    }

    // MARK: - Breakdown Card

    private func breakdownCard(_ result: SynastryResult) -> some View {
        let rs = result.relationshipScore
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(AstroTheme.accent)
                Text("Puan Detayı")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if rs.breakdown.isEmpty {
                Text("Bu haritalar arasında Discepolo puanlama kriterlerine uyan aspect bulunamadı.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                ForEach(rs.breakdown) { item in
                    HStack(spacing: 8) {
                        Text("+\(item.points)")
                            .font(.caption.bold().monospacedDigit())
                            .foregroundStyle(AstroTheme.harmonik)
                            .frame(width: 30, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.white)
                            Text(item.details)
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 2)
                }

                Divider().overlay(AstroTheme.cardBorder)

                HStack {
                    Spacer()
                    Text("Toplam: \(rs.scoreValue) puan")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Score Card (Aspect-Based)

    private func scoreCard(_ result: SynastryResult) -> some View {
        let score = result.aspectBasedScore
        return VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Aspect Bazlı Uyum")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ScoreRing(value: score, total: 100, tint: scoreColor(score), label: "/ 100", size: 104)

            Text(scoreText(score))
                .font(.subheadline.bold())
                .foregroundStyle(scoreColor(score))

            Text("\(result.crossAspects.count) cross-aspect analizi")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Categories

    private func categoriesCard(_ result: SynastryResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detaylı Uyum")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                categoryTile(icon: "heart.fill", title: "Duygusal Uyum", score: result.emotionalScore, color: AstroTheme.planet(.venus))
                categoryTile(icon: "bubble.left.fill", title: "İletişim", score: result.communicationScore, color: AstroTheme.air)
                categoryTile(icon: "flame.fill", title: "Tutku", score: result.passionScore, color: AstroTheme.planet(.mars))
                categoryTile(icon: "shield.fill", title: "Kararlılık", score: result.stabilityScore, color: AstroTheme.harmonik)
            }
        }
        .glassCard()
    }

    private func categoryTile(icon: String, title: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .kerning(1)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text("\(score)")
                .font(.system(size: 26, design: .serif))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.08))
                    Capsule().fill(color).frame(width: geo.size.width * min(Double(score) / 100, 1))
                }
            }
            .frame(height: 3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): 100 üzerinden \(score)")
    }

    // MARK: - Key Aspects

    private func keyAspectsCard(_ result: SynastryResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AstroTheme.accent)
                Text("Önemli Cross-Aspectler")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(result.keyAspects) { aspect in
                synastryAspectRow(aspect)
                if aspect.id != result.keyAspects.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }

            if result.keyAspects.isEmpty {
                Text("Bu haritalar arasında belirgin cross-aspect bulunmuyor.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
        }
        .glassCard()
    }

    private func synastryAspectRow(_ aspect: SynastryAspect) -> some View {
        AspectRow(aspect, name1: displayName1, name2: displayName2)
            .padding(.vertical, 3)
    }

    // MARK: - Bütüncül Yorum (sentez)

    private func synastryInterpretations(_ result: SynastryResult) -> some View {
        let guidances = result.crossAspects.map { asp in
            ChartSynthesizer.WeightedGuidance(
                item: SynastryInterpreter.interpretation(asp, name1: displayName1, name2: displayName2),
                weight: asp.weight / (asp.orb + 0.5),
                planets: [asp.planet1, asp.planet2]
            )
        }
        // Synastry iki ayrı kişinin haritası — tek-harita pattern'i (stellium/T-kare)
        // uygulanmaz; yalnız özet + tona göre gruplama.
        let synth = ChartSynthesizer.synthesize(guidances, structure: nil, context: .synastry)
        return ChartSynthesisSection(synthesis: synth)
    }

    // MARK: - Bi-Wheel Harita

    private func biWheelCard(_ result: SynastryResult) -> some View {
        let name1 = selectedPerson1?.name.isEmpty == false ? selectedPerson1!.name : "Kişi 1"
        let name2 = useManualEntry
            ? (partnerName.isEmpty ? "Partner" : partnerName)
            : (selectedPerson2?.name.isEmpty == false ? selectedPerson2!.name : "Kişi 2")

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "circle.circle.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Synastry Haritası")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Kişi etiketleri
            HStack {
                Label(name1, systemImage: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.white)
                Text("(iç halka)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                Spacer()
                Label(name2, systemImage: "person")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("(dış halka)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }

            SynastryBiWheelView(
                chart1: result.chart1,
                chart2: result.chart2,
                crossAspects: result.crossAspects,
                size: 320
            )
            .frame(maxWidth: .infinity)

            // Açıklama
            HStack(spacing: 12) {
                legendDot(AstroTheme.harmonik,  "Harmonik")
                legendDot(AstroTheme.zorlayici, "Zorlayıcı")
                legendDot(AstroTheme.notr,      "Nötr")
            }
            .frame(maxWidth: .infinity)
        }
        .glassCard()
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color.opacity(0.7)).frame(width: 7, height: 7)
            Text(label).font(.system(size: 9)).foregroundStyle(AstroTheme.textTertiary)
        }
    }

    // MARK: - Paylaşım

    private func synastryShareButton(_ result: SynastryResult) -> some View {
        Button {
            let name1 = selectedPerson1?.name ?? "Kişi 1"
            let name2 = useManualEntry ? (partnerName.isEmpty ? "Partner" : partnerName) : (selectedPerson2?.name ?? "Kişi 2")
            ShareImageRenderer.shareSynastry(
                person1Name: name1,
                person2Name: name2,
                result: result
            )
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Sonucu Paylaş")
            }
            .glassButton()
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func discepologColor(_ score: Int) -> Color {
        switch score {
        case 20...: AstroTheme.harmonik
        case 15..<20: AstroTheme.accentSecondary
        case 10..<15: AstroTheme.accent
        case 5..<10: AstroTheme.planet(.sun)
        default: AstroTheme.textSecondary
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 70...100: AstroTheme.harmonik
        case 50..<70: AstroTheme.accent
        case 30..<50: AstroTheme.planet(.sun)
        default: AstroTheme.zorlayici
        }
    }

    private func scoreText(_ score: Int) -> String {
        switch score {
        case 80...100: "Mükemmel Uyum"
        case 65..<80: "Güçlü Uyum"
        case 50..<65: "İyi Uyum"
        case 35..<50: "Zorlu Uyum"
        default: "Karmaşık Dinamik"
        }
    }


    // MARK: - Calculation

    /// Kayitli kisilerden hesapla
    private func calculateFromPeople() async {
        guard let p1 = selectedPerson1, let p2 = selectedPerson2 else { return }
        isLoading = true

        let coords1 = WorldCityStore.coordinates(for: p1.cityName, countryCode: "")
        let coords2 = WorldCityStore.coordinates(for: p2.cityName, countryCode: "")
        let tz1 = TimeZone(identifier: coords1.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        let tz2 = TimeZone(identifier: coords2.tz) ?? TimeZone(identifier: "Europe/Istanbul")!

        async let chart1 = appState.ephemeris.calculateBirthChart(
            date: p1.birthDate,
            latitude: p1.latitude,
            longitude: p1.longitude,
            timeZone: tz1
        )
        async let chart2 = appState.ephemeris.calculateBirthChart(
            date: p2.birthDate,
            latitude: p2.latitude,
            longitude: p2.longitude,
            timeZone: tz2
        )

        let c1 = await chart1
        let c2 = await chart2
        synastryResult = appState.ephemeris.calculateSynastry(chart1: c1, chart2: c2)
        isLoading = false
    }

    /// Manuel giristen hesapla
    private func calculateManual() async {
        guard let myChart = appState.currentChart else { return }
        isLoading = true

        let coords = WorldCityStore.coordinates(for: partnerCity, countryCode: partnerCountryCode)
        let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!

        let pChart = await appState.ephemeris.calculateBirthChart(
            date: partnerBirthDate,
            latitude: coords.lat,
            longitude: coords.lon,
            timeZone: tz
        )
        synastryResult = appState.ephemeris.calculateSynastry(chart1: myChart, chart2: pChart)
        isLoading = false
    }
}
