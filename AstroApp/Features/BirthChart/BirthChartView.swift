import SwiftUI

/// Doğum Haritası sayfası — tek sayfa, üç mod:
///   ana        — yaşayan çark (yavaş döner; seçili kişinin Güneş/Ay'ı), kişi çipleri, geçmiş okumalar
///   hesaplama  — çark bir tur atar, gezegenler içeri uçar, açılar çizilir
///   sonuç      — çark büyür, altında Büyük Üçlü + mevcut sonuç içeriği; gezegene dokununca açılar parlar
/// "Yeni kişi" çipi manuel giriş sheet'ini açar; tekerlekler çevrildikçe çark canlı akar.
struct BirthChartView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements

    /// Hazır bir haritayla doğrudan sonuç modunda açmak için (Astroloji sekmesi kestirmesi)
    var initialChart: BirthChart? = nil
    var initialName: String = ""

    @State private var model = LiveChartWheelModel()
    @State private var selectedPersonID: UUID?
    @State private var previewCache: [UUID: BirthChart] = [:]
    @State private var previewTask: Task<Void, Never>?
    @State private var previewChart: BirthChart?
    @State private var isPreviewLoading = false

    @State private var resultChart: BirthChart?
    @State private var resultName = ""
    @State private var highlighted: PlanetPosition?

    @State private var showManual = false
    @State private var pendingManual: (data: BirthData, chart: BirthChart)?
    @State private var showPayment = false
    @State private var pendingBirthData: BirthData?
    @State private var isCalculating = false
    @State private var showAllHistory = false

    private let wheelSize: CGFloat = 340
    private let selectionHaptic = UISelectionFeedbackGenerator()

    private var people: [BirthData] { appState.birthDataStore.people }
    private var isResult: Bool { model.mode == .result }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    wheelBlock

                    if isResult {
                        resultSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        homeSection
                            .opacity(model.mode == .home ? 1 : 0.25)
                            .disabled(model.mode != .home)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
                .offset(y: model.mode == .manual ? -110 : 0)
            }
            .scrollDisabled(model.mode == .manual)
        }
        .animation(.spring(duration: 0.6, bounce: 0.08), value: model.mode)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(isResult)
        .toolbar {
            if isResult {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: backToHome) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .sheet(isPresented: $showManual, onDismiss: manualDismissed) {
            ManualBirthEntrySheet(
                onPreview: { chart in
                    previewChart = chart
                    model.setTargets(chart: chart)
                },
                onSave: { data, chart in
                    pendingManual = (data, chart)
                    showManual = false
                }
            )
            .astroSheetStyle(detents: [.fraction(0.58), .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.58)))
        }
        .sheet(isPresented: $showPayment) {
            ChartPaymentSheet {
                showPayment = false
                if let data = pendingBirthData {
                    pendingBirthData = nil
                    runCalculation(person: data, knownChart: nil, charge: true, fly: true)
                }
            }
        }
        .sheet(item: $highlighted) { position in
            if let chart = resultChart {
                PlanetInterpretationSheet(
                    position: position,
                    chart: chart,
                    sections: appState.interpretation.interpretations(forPlanet: position.planet, in: chart)
                )
            }
        }
        .onAppear(perform: setup)
    }

    // MARK: - Başlık

    private var header: some View {
        VStack(spacing: 6) {
            Text(isResult ? resultName : "Doğum Haritası")
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.opacity)
            Text(isResult ? "Doğum haritası" : "Yıldızların sana ne söylüyor?")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .contentTransition(.opacity)
        }
        .padding(.top, 12)
        .opacity(model.mode == .manual ? 0 : 1)
    }

    // MARK: - Çark

    private var wheelBlock: some View {
        let scale: CGFloat = isResult ? 1 : 0.8
        return ZStack {
            LiveChartWheelView(model: model, size: wheelSize) { planet in
                model.toggleSelection(planet)
            }
            if model.mode == .home {
                centerOverlay
                    .transition(.opacity)
            }
        }
        .frame(width: wheelSize, height: wheelSize)
        .scaleEffect(scale, anchor: .top)
        .frame(height: wheelSize * scale)
        .padding(.top, 10)
    }

    /// Ana modda çarkın ortası: seçili kişinin Güneş · Ay · Yükselen burcu
    private var centerOverlay: some View {
        VStack(spacing: 2) {
            if let chart = previewChart {
                centerLine("☉\u{FE0E}", chart.sunSign)
                centerLine("☽\u{FE0E}", chart.moonSign)
                centerLine("↑", chart.ascendant)
            }
        }
        .font(.system(size: 17, weight: .semibold, design: .serif))
        .opacity(isPreviewLoading ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: isPreviewLoading)
        .animation(.easeInOut(duration: 0.2), value: previewChart?.birthDate)
        .allowsHitTesting(false)
    }

    private func centerLine(_ glyph: String, _ sign: ZodiacSign?) -> some View {
        HStack(spacing: 6) {
            Text(glyph)
                .foregroundStyle(sign.map { AstroTheme.element($0.element) } ?? .white)
                .frame(width: 22)
            Text(sign?.name ?? "—")
                .foregroundStyle(.white)
        }
    }

    // MARK: - Ana mod

    private var homeSection: some View {
        VStack(spacing: 14) {
            chips

            Button(action: calculateTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                    Text(isCalculating ? "Hesaplanıyor…" : (people.isEmpty ? "Doğum bilgilerini gir" : "Haritayı Hesapla"))
                }
                .frame(maxWidth: .infinity)
                .glassButton()
            }
            .disabled(isCalculating)

            historySection
        }
        .padding(.top, 6)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(people) { person in
                    personChip(person)
                }
                addChip
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, -4)
        .accessibilityLabel("Kişi seç")
    }

    private func personChip(_ person: BirthData) -> some View {
        let sign = sunSign(for: person)
        let color = AstroTheme.element(sign.element)
        let isOn = person.id == selectedPersonID
        return Button {
            selectPerson(person.id)
        } label: {
            VStack(spacing: 8) {
                Text(sign.glyph)
                    .font(.system(size: 20, design: .serif))
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.16), in: .circle)
                Text(person.name.isEmpty ? "İsimsiz" : person.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(isOn ? .white : AstroTheme.textSecondary)
            }
            .frame(width: 76)
            .padding(.vertical, 12)
            .background(isOn ? AstroTheme.accent.opacity(0.14) : AstroTheme.surface, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isOn ? color.opacity(0.9) : AstroTheme.cardBorder, lineWidth: 1)
            }
            .shadow(color: isOn ? color.opacity(0.45) : .clear, radius: 11)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: isOn)
        .accessibilityLabel("\(person.name), \(sign.name)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var addChip: some View {
        Button(action: openManual) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AstroTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .overlay { Circle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3])).foregroundStyle(AstroTheme.textTertiary) }
                Text("Yeni kişi")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
            .frame(width: 76)
            .padding(.vertical, 12)
            .background(AstroTheme.surface, in: .rect(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    // MARK: Geçmiş okumalar

    @ViewBuilder
    private var historySection: some View {
        let readings = appState.chartReadingStore.readings.sorted { $0.calculatedAt > $1.calculatedAt }
        if !readings.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Geçmiş okumalar")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(readings.count) okuma")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(.bottom, 4)

                ForEach(showAllHistory ? readings : Array(readings.prefix(3))) { reading in
                    historyRow(reading)
                }

                if readings.count > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { showAllHistory.toggle() }
                    } label: {
                        Text(showAllHistory ? "Daha az göster" : "Tümünü gör (\(readings.count))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AstroTheme.accent)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(.top, 24)
        }
    }

    private func historyRow(_ reading: SavedChartReading) -> some View {
        let chart = reading.chart
        let sun = chart.sunSign
        let color = sun.map { AstroTheme.element($0.element) } ?? AstroTheme.accent
        return Button {
            openReading(reading)
        } label: {
            HStack(spacing: 14) {
                Text(sun?.glyph ?? "✦")
                    .font(.system(size: 21, design: .serif))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.14), in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(reading.personName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 10) {
                        if let sun { Text("☉\u{FE0E} \(sun.name)") }
                        if let moon = chart.moonSign { Text("☽\u{FE0E} \(moon.name)") }
                        if let asc = chart.ascendant { Text("↑ \(asc.name)") }
                    }
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                }

                Spacer()

                Text(reading.calculatedAt.formatted(.relative(presentation: .named).locale(Locale(identifier: "tr_TR"))))
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(AstroTheme.cardBorder).frame(height: 1) }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sonuç modu

    @ViewBuilder
    private var resultSection: some View {
        if let chart = resultChart {
            VStack(spacing: 16) {
                highlightBar(chart)
                BirthChartResultView(chart: chart, personName: resultName, embedded: true)
            }
            .padding(.top, 10)
        }
    }

    /// Çarkta vurgulanan gezegen → satır + yorum; yoksa ipucu
    @ViewBuilder
    private func highlightBar(_ chart: BirthChart) -> some View {
        if let planet = model.selectedPlanet,
           let position = chart.planets.first(where: { $0.planet == planet }) {
            Button {
                highlighted = position
            } label: {
                HStack(spacing: 6) {
                    PlanetRow(position: position)
                    Text("Yorum")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AstroTheme.accent)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AstroTheme.accent.opacity(0.14), in: .rect(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.accent.opacity(0.35), lineWidth: 1) }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        } else {
            Text("Bir gezegene dokun, açıları haritada parlasın")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
                .padding(.vertical, 6)
                .transition(.opacity)
        }
    }

    // MARK: - Mantık

    private func setup() {
        if let initialChart {
            resultChart = initialChart
            resultName = initialName.isEmpty ? "Haritam" : initialName
            previewChart = initialChart
            model.setTargets(chart: initialChart, instant: true)
            model.showResult(haptic: false)
            return
        }
        if selectedPersonID == nil {
            selectedPersonID = appState.birthDataStore.ownerPerson?.id ?? people.first?.id
        }
        if let id = selectedPersonID {
            loadPreview(for: id, animated: false)
        }
    }

    private func sunSign(for person: BirthData) -> ZodiacSign {
        if let chart = cachedChart(for: person), let sun = chart.sunSign { return sun }
        return ZodiacSign.from(birthDate: person.birthDate)
    }

    /// Daha önce hesaplanmış (önizleme ya da kaydedilmiş) harita
    private func cachedChart(for person: BirthData) -> BirthChart? {
        if let chart = previewCache[person.id] { return chart }
        if let reading = appState.chartReadingStore.reading(forPersonID: person.id), reading.birthData == person {
            return reading.chart
        }
        return nil
    }

    private func computeChart(for data: BirthData) async -> BirthChart {
        let coords = WorldCityStore.coordinates(for: data.cityName, countryCode: "TR")
        let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        return await appState.ephemeris.calculateBirthChart(
            date: data.birthDate, latitude: data.latitude, longitude: data.longitude, timeZone: tz)
    }

    private func selectPerson(_ id: UUID) {
        guard model.mode == .home, id != selectedPersonID else { return }
        selectedPersonID = id
        selectionHaptic.selectionChanged()
        loadPreview(for: id, animated: true)
    }

    /// Seçili kişinin haritasını (ücretsiz önizleme) çarka yükler
    private func loadPreview(for id: UUID, animated: Bool) {
        guard let person = people.first(where: { $0.id == id }) else { return }
        previewTask?.cancel()
        if let chart = cachedChart(for: person) {
            applyPreview(chart, instant: !animated)
            return
        }
        isPreviewLoading = true
        previewTask = Task {
            let chart = await computeChart(for: person)
            guard !Task.isCancelled else { return }
            previewCache[id] = chart
            isPreviewLoading = false
            applyPreview(chart, instant: !animated)
        }
    }

    private func applyPreview(_ chart: BirthChart, instant: Bool) {
        previewChart = chart
        model.setTargets(chart: chart, instant: instant)
    }

    private func calculateTapped() {
        guard model.mode == .home else { return }
        guard let id = selectedPersonID, let person = people.first(where: { $0.id == id }) else {
            openManual()
            return
        }
        // Aynı doğum verisiyle daha önce hesaplanmış → ücretsiz
        if let reading = appState.chartReadingStore.reading(forPersonID: id), reading.birthData == person {
            runCalculation(person: person, knownChart: reading.chart, charge: false, fly: true)
            return
        }
        if entitlements.canCalculateChart {
            runCalculation(person: person, knownChart: nil, charge: true, fly: true)
        } else {
            pendingBirthData = person
            showPayment = true
        }
    }

    /// Hesaplama sahnesi: haritayı hazırla → çark bir tur atar, gezegenler uçar → sonuç
    private func runCalculation(person: BirthData, knownChart: BirthChart?, charge: Bool, fly: Bool) {
        guard !isCalculating else { return }
        isCalculating = true
        Task {
            let chart: BirthChart
            if let knownChart {
                chart = knownChart
            } else if let cached = cachedChart(for: person) {
                chart = cached
            } else {
                chart = await computeChart(for: person)
                previewCache[person.id] = chart
            }

            if charge {
                if !EntitlementManager.isAdmin {
                    _ = appState.store.consumeChartCredit()
                }
                appState.chartReadingStore.saveReading(
                    SavedChartReading(personID: person.id, personName: person.name, birthData: person, chart: chart))
            }

            let hadPreview = previewChart != nil
            previewChart = chart
            model.setTargets(chart: chart, instant: !hadPreview)
            let duration = model.startCalculation(fly: fly)
            try? await Task.sleep(for: .seconds(duration))

            resultChart = chart
            resultName = person.name.isEmpty ? "Haritam" : person.name
            model.showResult()
            isCalculating = false
        }
    }

    private func openReading(_ reading: SavedChartReading) {
        guard model.mode == .home, !isCalculating else { return }
        if people.contains(where: { $0.id == reading.personID }) {
            selectedPersonID = reading.personID
        }
        applyPreview(reading.chart, instant: false)
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            runCalculation(person: reading.birthData, knownChart: reading.chart, charge: false, fly: false)
        }
    }

    private func backToHome() {
        model.enterHome()
        if let id = selectedPersonID {
            loadPreview(for: id, animated: true)
        }
    }

    // MARK: Manuel giriş

    private func openManual() {
        guard model.mode == .home else { return }
        model.openManual()
        showManual = true
    }

    private func manualDismissed() {
        model.closeManual()
        if let pending = pendingManual {
            pendingManual = nil
            appState.birthDataStore.addPerson(pending.data)
            previewCache[pending.data.id] = pending.chart
            selectedPersonID = pending.data.id
            applyPreview(pending.chart, instant: true)
            if entitlements.canCalculateChart {
                runCalculation(person: pending.data, knownChart: pending.chart, charge: true, fly: false)
            } else {
                pendingBirthData = pending.data
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    showPayment = true
                }
            }
        } else if let id = selectedPersonID {
            loadPreview(for: id, animated: true)
        }
    }
}
