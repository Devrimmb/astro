import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var moonPhase = MoonPhaseCalculator.currentPhase()
    @State private var currentPlanetaryHour: PlanetaryHour?
    @State private var activeRetrogrades: [RetrogradeCalculator.RetrogradePeriod] = []
    @State private var dailyTip: String?
    @State private var todayEvents: [CalendarEvent] = []
    @State private var todayPlanets: [PlanetPosition] = []
    @State private var guidance: DailyCosmicCoach.DailyGuidance?
    @State private var lifeCycleEvents: [LifeCycleEvent] = []
    @State private var showIdentity = false

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        greetingSection
                        birthdayIdentityCard
                        cosmicCoachCard
                        if appState.currentChart != nil { bigThreeCard }
                        lifeCycleCard
                        todayPlanetsCard
                        moonAndHourTiles
                        todayCalendarCard
                        if !activeRetrogrades.isEmpty { retrogradeCard }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("AstroApp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadData()
            }
            .task {
                let positions = await Task.detached(priority: .userInitiated) {
                    TransitCalculator.calculatePositions(for: .now)
                }.value
                todayPlanets = positions
                SharedDefaults.saveTodayPlanets(from: positions)
            }
            .task(id: appState.birthDataStore.savedData) {
                guard let person = appState.birthDataStore.savedData else {
                    lifeCycleEvents = []
                    return
                }
                lifeCycleEvents = await LifeCycleCache.events(for: person, appState: appState)
            }
            .onChange(of: appState.currentChart?.sunSign) { _, _ in
                loadData()
            }
        }
    }

    // MARK: - Karşılama

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let name = appState.birthDataStore.savedData?.name, !name.isEmpty {
                    Text("\(greetingText), ")
                        .foregroundStyle(.white)
                    + Text(name)
                        .italic()
                        .foregroundStyle(AstroTheme.accentSecondary)
                } else {
                    Text(greetingText)
                        .foregroundStyle(.white)
                }
            }
            .font(.largeTitle)
            .fontDesign(.serif)
            .lineLimit(2)
            .minimumScaleFactor(0.8)

            HStack(spacing: 4) {
                Text(todayDateText)
                if let sign = moonPhase.moonSign {
                    Text("·")
                    Text("Ay \(sign.glyph) \(sign.name)'da")
                        .foregroundStyle(AstroTheme.accentSecondary)
                }
            }
            .font(.caption)
            .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.horizontal, 2)
    }

    // MARK: - Kozmik Koç

    private var cosmicCoachCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kozmik Koçun")
                    .font(.headline)
                    .foregroundStyle(.white)
                InfoTip(
                    title: "Kozmik Koçun",
                    message: "Her gün, bugünün gökyüzü ile senin doğum haritan karşılaştırılarak sana özel rehberlik üretilir. Genel gökyüzü durumu herkese aynıdır; 'Sana Özel' kısmı yalnızca senin haritana göredir."
                )
                Spacer()
            }

            if let g = guidance, !g.isEmpty {
                // Bugünün Gökyüzü (genel)
                if !g.cosmicWeather.isEmpty {
                    sectionLabel("Bugünün Gökyüzü")
                    ForEach(g.cosmicWeather) { item in
                        guidanceRow(item)
                    }
                }

                if let mood = g.moonMood {
                    guidanceRow(mood)
                }

                // Sana Özel (kişisel transitler)
                if appState.currentChart != nil {
                    if !g.personalTransits.isEmpty {
                        sectionLabel("Sana Özel")
                        ForEach(g.personalTransits) { item in
                            guidanceRow(item)
                        }
                    }
                } else {
                    personalTransitCTA
                }
            } else if appState.currentChart == nil {
                personalTransitCTA
            } else {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .glassCard(tint: AstroTheme.accent)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(AstroTheme.textTertiary)
            .textCase(.uppercase)
            .padding(.top, 2)
    }

    private func guidanceRow(_ item: DailyCosmicCoach.GuidanceItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.icon)
                .font(.callout)
                .foregroundStyle(AstroTheme.tone(item.tone))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text(item.message)
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var personalTransitCTA: some View {
        VStack(spacing: 0) {
            sectionLabel("Sana Özel")
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.callout)
                    .foregroundStyle(AstroTheme.accent)
                    .frame(width: 22)
                Text("Doğum haritanı oluştur, her gün sana özel transit rehberliği burada görünsün.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Ay Fazı + Gezegen Saati (yan yana)

    private var moonAndHourTiles: some View {
        HStack(alignment: .top, spacing: 12) {
            moonPhaseCard
            planetaryHourCard
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var moonPhaseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                sectionLabel("Ay Fazı")
                InfoTip(
                    title: "Ay Fazları",
                    message: "Ay'ın evresi duygularını ve enerjini etkiler. Yeni Ay yeni başlangıçlar, Dolunay ise sonuçlanma ve farkındalık zamanıdır."
                )
            }
            HStack(spacing: 10) {
                MoonDisc(info: moonPhase, size: 40, glow: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(moonPhase.phase.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text("%\(Int(moonPhase.illumination * 100)) aydınlık")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassCard(cornerRadius: 16, padding: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Günlük Takvim Özeti

    private var todayCalendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                AstroCalendarContent()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(AstroTheme.accentSecondary)
                    Text("Bugünün Takvimi")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
            }

            if let tip = dailyTip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(AstroTheme.planet(.sun))
                        .font(.caption)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            if !todayEvents.isEmpty {
                ForEach(todayEvents) { event in
                    HStack(spacing: 8) {
                        Image(systemName: event.icon)
                            .font(.caption2)
                            .foregroundStyle(calendarEventColor(event.type))
                        Text(event.title)
                            .font(.caption)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(event.subtitle)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .glassCard()
    }

    private func calendarEventColor(_ type: CalendarEventType) -> Color {
        switch type {
        case .moonPhase: AstroTheme.planet(.moon)
        case .eclipse: AstroTheme.accent
        case .retrograde: AstroTheme.zorlayici
        case .voidOfCourse: AstroTheme.water
        case .planetaryHour: AstroTheme.planet(.saturn)
        }
    }

    // MARK: - Gezegen Saati

    private var planetaryHourCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Gezegen Saati")
            if let hour = currentPlanetaryHour {
                HStack(spacing: 10) {
                    Text(hour.planet.glyph)
                        .font(.system(size: 22, design: .serif))
                        .foregroundStyle(AstroTheme.planet(hour.planet))
                        .frame(width: 40, height: 40)
                        .background(AstroTheme.planet(hour.planet).opacity(0.12), in: .circle)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hour.planet.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AstroTheme.planet(hour.planet))
                        Text(hour.timeText)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                }
            } else {
                Text("Hesaplanıyor...")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassCard(cornerRadius: 16, padding: 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Bugünün Gezegenleri

    private var todayPlanetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "circle.hexagonpath")
                    .foregroundStyle(AstroTheme.accentSecondary)
                Text("Bugünün Gezegenleri")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if todayPlanets.isEmpty {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(todayPlanets) { pos in
                            VStack(spacing: 5) {
                                Text(pos.planet.glyph)
                                    .font(.system(size: 18, design: .serif))
                                    .foregroundStyle(AstroTheme.planet(pos.planet))
                                Text(pos.planet.name)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                HStack(spacing: 2) {
                                    Text(pos.sign.glyph)
                                        .fontDesign(.serif)
                                        .foregroundStyle(AstroTheme.element(pos.sign.element))
                                    Text(String(format: "%.0f°", pos.degree))
                                        .foregroundStyle(AstroTheme.textSecondary)
                                        .monospacedDigit()
                                }
                                .font(.caption2)
                                Text(pos.isRetrograde ? "℞" : " ")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(AstroTheme.zorlayici)
                            }
                            .frame(width: 64)
                            .padding(.vertical, 8)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(pos.planet.name), \(pos.sign.name) \(String(format: "%.0f", pos.degree)) derece\(pos.isRetrograde ? ", retrograd" : "")")
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .scrollClipDisabled()
            }
        }
        .glassCard()
    }

    // MARK: - Retrograde Durumu

    private var retrogradeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.backward.circle")
                    .foregroundStyle(AstroTheme.zorlayici)
                Text("Aktif Retrogradlar")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(activeRetrogrades) { retro in
                HStack(spacing: 10) {
                    Text(retro.planet.glyph)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(AstroTheme.planet(retro.planet))
                        .frame(width: 28, height: 28)
                        .background(AstroTheme.planet(retro.planet).opacity(0.12), in: .circle)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(retro.planet.name) Retrograde")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text("\(retro.startText) – \(retro.endText)")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    Spacer()
                    Text(retro.startSign.glyph)
                        .font(.title3)
                        .fontDesign(.serif)
                        .foregroundStyle(AstroTheme.element(retro.startSign.element))
                }
            }
        }
        .glassCard()
    }

    // MARK: - Doğum günü

    /// Doğum gününe ±7 gün kala: yeni yaşın kozmik kimlik hikâyesi
    @ViewBuilder
    private var birthdayIdentityCard: some View {
        if let person = appState.birthDataStore.savedData,
           let chart = appState.currentChart,
           Self.isNearBirthday(person.birthDate) {
            Button {
                showIdentity = true
            } label: {
                HStack(spacing: 14) {
                    Text("🎂")
                        .font(.system(size: 30))
                        .frame(width: 50, height: 50)
                        .background(AstroTheme.planet(.sun).opacity(0.15), in: .circle)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Calendar.current.isDateInToday(Self.birthday(of: person.birthDate) ?? .distantPast)
                             ? "Doğum günün kutlu olsun!" : "Doğum günün yaklaşıyor")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Yeni yaşının kozmik kimliği hazır")
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.planet(.sun))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "sparkles")
                        .foregroundStyle(AstroTheme.planet(.sun))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showIdentity) {
                CosmicIdentityStoryView(chart: chart, name: person.name, cityName: person.cityName)
            }
        }
    }

    /// Bu yılki doğum günü (29 Şubat → artık olmayan yılda 28 Şubat)
    static func birthday(of birthDate: Date, in year: Int? = nil, now: Date = .now) -> Date? {
        let cal = Calendar.current
        let md = cal.dateComponents([.month, .day], from: birthDate)
        let y = year ?? cal.component(.year, from: now)
        var comps = DateComponents(year: y, month: md.month, day: md.day)
        if md.month == 2, md.day == 29, cal.date(from: DateComponents(year: y, month: 2, day: 29)).map({ cal.component(.month, from: $0) }) != 2 {
            comps.day = 28
        }
        return cal.date(from: comps)
    }

    /// Bugün, doğum gününe (yıl geçişi dahil) 7 günden yakın mı
    static func isNearBirthday(_ birthDate: Date, now: Date = .now) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        let year = cal.component(.year, from: now)
        return [year - 1, year, year + 1].contains { y in
            guard let b = birthday(of: birthDate, in: y, now: now) else { return false }
            let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: b)).day ?? 99
            return abs(days) <= 7
        }
    }

    // MARK: - Hayat Döngüleri

    /// Sıradaki (ya da içinde bulunulan) büyük dönemeç; dokununca Hayat Döngüleri açılır
    @ViewBuilder
    private var lifeCycleCard: some View {
        if let person = appState.birthDataStore.savedData,
           let highlight = LifeCycleTiming.highlight(lifeCycleEvents) {
            let event = highlight.event
            let color = AstroTheme.planet(event.kind.planet)
            NavigationLink {
                LifeCyclesView(initialPerson: person)
            } label: {
                HStack(spacing: 14) {
                    Text(event.kind.planet.glyph)
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(color)
                        .frame(width: 50, height: 50)
                        .background(color.opacity(0.15), in: .circle)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(highlight.isActive ? "ŞU AN İÇİNDESİN" : "SIRADAKİ DÖNEMECİN")
                            .font(.caption2.weight(.bold))
                            .kerning(1)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text(LifeCycleTiming.title(event))
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(highlight.isActive
                             ? LifeCycleTiming.dateRange(event)
                             : "\(LifeCycleTiming.countdown(to: event.start)) · \(LifeCycleTiming.ageText(event, birthDate: person.birthDate))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
            .buttonStyle(.plain)
            .accessibilityHint("Hayat döngülerini açar")
        }
    }

    // MARK: - Büyük Üçlü

    private var bigThreeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Büyük Üçlün")
                    .font(.headline)
                    .foregroundStyle(.white)
                InfoTip(
                    title: "Büyük Üçlü",
                    message: "Güneş burcun kişiliğini, Ay burcun duygularını, Yükselen burcun ise dış görünümünü temsil eder. Doğum haritandan hesaplanır."
                )
            }

            if let chart = appState.currentChart {
                HStack(spacing: 8) {
                    if let sun = chart.sunSign {
                        bigThreeItem(label: "Güneş", sign: sun, glyph: "☉", color: AstroTheme.planet(.sun))
                    }
                    if let moon = chart.moonSign {
                        bigThreeItem(label: "Ay", sign: moon, glyph: "☽", color: AstroTheme.planet(.moon))
                    }
                    if let asc = chart.ascendant {
                        bigThreeItem(label: "Yükselen", sign: asc, glyph: "AC", color: AstroTheme.harmonik)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yardımcılar

    private func bigThreeItem(label: String, sign: ZodiacSign, glyph: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(glyph)
                .font(.system(size: 22, design: .serif))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .kerning(1)
                .foregroundStyle(AstroTheme.textTertiary)
            Text(sign.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AstroTheme.surface, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AstroTheme.cardBorder, lineWidth: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(sign.name)")
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return LanguageManager.localized("Günaydın")
        case 12..<18: return LanguageManager.localized("İyi Günler")
        case 18..<22: return LanguageManager.localized("İyi Akşamlar")
        default: return LanguageManager.localized("İyi Geceler")
        }
    }

    private var todayDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: .now)
    }

    // MARK: - Veri Yükleme

    private func loadData() {
        // Günlük burç — chart yoksa doğum tarihinden hesapla
        // Ay fazı
        moonPhase = MoonPhaseCalculator.currentPhase()

        // Gezegen saati (İstanbul default)
        let lat = appState.birthDataStore.savedData?.latitude ?? 41.0082
        let lon = appState.birthDataStore.savedData?.longitude ?? 28.9784
        let now = Date.now
        let dailyHours = PlanetaryHourCalculator.calculate(date: now, latitude: lat, longitude: lon)
        currentPlanetaryHour = dailyHours.currentHour
        // Gece yarısından sonra, bugünün saatlerinde bulunamazsa dünün gece saatlerini dene
        if currentPlanetaryHour == nil {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            let yesterdayHours = PlanetaryHourCalculator.calculate(date: yesterday, latitude: lat, longitude: lon)
            currentPlanetaryHour = yesterdayHours.currentHour
        }

        // Aktif retrogradlar
        let year = Calendar.current.component(.year, from: .now)
        let retrogrades = RetrogradeCalculator.calculate(year: year)
        activeRetrogrades = retrogrades.filter { $0.isActive }

        // Günlük takvim özeti
        let today = Date.now
        let calendar = Calendar.current
        var events: [CalendarEvent] = []

        // Önemli ay fazları
        let isSignificantPhase = [MoonPhaseName.newMoon, .fullMoon, .firstQuarter, .lastQuarter].contains(moonPhase.phase)
        if isSignificantPhase {
            events.append(CalendarEvent(
                date: today, type: .moonPhase,
                title: moonPhase.phase.name,
                subtitle: moonPhase.moonSign?.name ?? "",
                icon: moonPhase.phase.symbolName
            ))
        }

        // Tutulmalar
        let eclipses = EclipseCalculator.calculate(year: year)
        for eclipse in eclipses where calendar.isDate(eclipse.date, inSameDayAs: today) {
            events.append(CalendarEvent(
                date: eclipse.date, type: .eclipse,
                title: eclipse.type.rawValue,
                subtitle: "\(eclipse.sign.name) \(String(format: "%.0f", eclipse.degree))°",
                icon: eclipse.isSolar ? "sun.max.trianglebadge.exclamationmark" : "moon.circle"
            ))
        }

        // Retrograde başlangıç/bitiş
        for retro in retrogrades {
            if calendar.isDate(retro.startDate, inSameDayAs: today) {
                events.append(CalendarEvent(
                    date: retro.startDate, type: .retrograde,
                    title: "\(retro.planet.name) Retrograde Başlangıç",
                    subtitle: retro.startSign.name,
                    icon: "arrow.backward.circle.fill"
                ))
            }
        }

        // VOC
        let vocPeriods = VoidOfCourseCalculator.calculate(fromDate: today, days: 1)
        for voc in vocPeriods where calendar.isDate(voc.startDate, inSameDayAs: today) {
            events.append(CalendarEvent(
                date: voc.startDate, type: .voidOfCourse,
                title: "Ay Boşlukta",
                subtitle: "\(voc.fromSign.name) → \(voc.toSign.name)",
                icon: "moon.haze"
            ))
        }
        todayEvents = events

        // Günlük tavsiye
        let isVOC = vocPeriods.contains { $0.startDate <= today && today <= $0.endDate }
        let hasEclipse = eclipses.contains { calendar.isDate($0.date, inSameDayAs: today) }
        dailyTip = DailyTipGenerator.generate(
            moonPhase: moonPhase,
            isVOC: isVOC,
            activeRetrogrades: activeRetrogrades,
            hasEclipse: hasEclipse
        )

        // Kişiselleştirilmiş günlük rehberlik (transit hesabı ağır → arka planda)
        let chart = appState.currentChart
        let phase = moonPhase
        let retros = activeRetrogrades
        let todayEclipses = eclipses.filter { calendar.isDate($0.date, inSameDayAs: today) }
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                DailyCosmicCoach.guidance(
                    natalChart: chart,
                    date: today,
                    moonPhase: phase,
                    activeRetrogrades: retros,
                    isVOC: isVOC,
                    todayEclipses: todayEclipses
                )
            }.value
            guidance = result
        }
    }
}
