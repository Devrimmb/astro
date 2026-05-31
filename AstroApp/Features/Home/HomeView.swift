import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var moonPhase = MoonPhaseCalculator.currentPhase()
    @State private var currentPlanetaryHour: PlanetaryHour?
    @State private var activeRetrogrades: [RetrogradeCalculator.RetrogradePeriod] = []
    @State private var dailyTip: String?
    @State private var todayEvents: [CalendarEvent] = []
    @State private var todayPlanets: [PlanetPosition] = []

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        greetingSection
                        streakBanner
                        if appState.currentChart != nil { bigThreeCard }
                        todayPlanetsCard
                        todayCalendarCard
                        if !activeRetrogrades.isEmpty { retrogradeCard }
                        moonPhaseCard
                        planetaryHourCard
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
                appState.gamification.dailyCheckIn()
            }
            .task {
                let positions = await Task.detached(priority: .userInitiated) {
                    TransitCalculator.calculatePositions(for: .now)
                }.value
                todayPlanets = positions
                SharedDefaults.saveTodayPlanets(from: positions)
            }
            .onChange(of: appState.currentChart?.sunSign) { _, _ in
                loadData()
            }
        }
    }

    // MARK: - Karşılama

    private var greetingSection: some View {
        VStack(spacing: 6) {
            Text(greetingText)
                .font(.title2.bold())
                .foregroundStyle(.white)
            if let name = appState.birthDataStore.savedData?.name, !name.isEmpty {
                Text("\(LanguageManager.localized("Merhaba")), \(name)")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }
            Text(todayDateText)
                .font(.caption)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .padding(.top, 8)
    }

    // MARK: - Streak Banner

    private var streakBanner: some View {
        let gm = appState.gamification

        return HStack(spacing: 14) {
            // Streak ateşi
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(gm.currentStreak > 0 ? .orange : AstroTheme.textTertiary)
                Text("\(gm.currentStreak)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text("gün")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .frame(width: 56)

            // Seviye + yıldız
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: gm.currentLevel.icon)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.accent)
                    Text(gm.currentLevel.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text("\(gm.totalStars)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        InfoTip(
                            title: "Kozmik Yıldızlar",
                            message: "Her gün uygulamayı açarak, fal bakarak ve sonuçları paylaşarak yıldız kazan! Yıldızlar seni yeni seviyelere taşır. Üst üste giriş yaptıkça bonus çarpanın artar."
                        )
                    }
                }

                // İlerleme çubuğu
                if gm.nextLevel != nil {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [AstroTheme.accent, AstroTheme.accent.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * gm.levelProgress)
                        }
                    }
                    .frame(height: 6)
                }

                HStack {
                    if let bonus = gm.streakBonusText {
                        Text(bonus)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    Spacer()

                    if let next = gm.nextLevel {
                        Text("\(next.requiredStars - gm.totalStars) ⭐ → \(next.name)")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Ay Fazı

    private var moonPhaseCard: some View {
        HStack(spacing: 14) {
            Image(systemName: moonPhaseIcon)
                .font(.system(size: 36))
                .foregroundStyle(.yellow.opacity(0.8))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Ay Fazı")
                        .font(.caption.bold())
                        .foregroundStyle(AstroTheme.textTertiary)
                    InfoTip(
                        title: "Ay Fazları",
                        message: "Ay'ın evresi duygularını ve enerjini etkiler. Yeni Ay yeni başlangıçlar, Dolunay ise sonuçlanma ve farkındalık zamanıdır."
                    )
                }
                Text(moonPhase.phase.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Text("Aydınlanma: %\(Int(moonPhase.illumination * 100))")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                    if let sign = moonPhase.moonSign {
                        Text("·")
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text("\(sign.glyph) \(sign.name)")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.accentSecondary)
                    }
                }
            }

            Spacer()
        }
        .glassCard()
    }

    // MARK: - Günlük Takvim Özeti

    private var todayCalendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink {
                AstroCalendarContent()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.blue)
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
                        .foregroundStyle(.yellow)
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
        case .moonPhase: .cyan
        case .eclipse: .indigo
        case .retrograde: .red
        case .voidOfCourse: Color(red: 0.6, green: 0.5, blue: 0.8)
        case .planetaryHour: .brown
        }
    }

    // MARK: - Gezegen Saati

    private var planetaryHourCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "clock.fill")
                .font(.title2)
                .foregroundStyle(AstroTheme.accent)
                .frame(width: 44, height: 44)
                .background(AstroTheme.accent.opacity(0.15), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text("Gezegen Saati")
                    .font(.caption.bold())
                    .foregroundStyle(AstroTheme.textTertiary)
                if let hour = currentPlanetaryHour {
                    Text(hour.planet.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(hour.timeText)
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                } else {
                    Text("Hesaplanıyor...")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }

            Spacer()
        }
        .glassCard()
    }

    // MARK: - Bugünün Gezegenleri

    private var todayPlanetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Bugünün Gökyüzü")
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
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(todayPlanets) { pos in
                        HStack(spacing: 6) {
                            Text(planetGlyph(pos.planet))
                                .font(.system(size: 14))
                                .frame(width: 20, alignment: .center)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 3) {
                                    Text(pos.planet.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    if pos.isRetrograde {
                                        Text("℞")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                    }
                                }
                                HStack(spacing: 3) {
                                    Text(pos.sign.glyph)
                                    Text(pos.sign.name)
                                        .lineLimit(1)
                                }
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textSecondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
                    }
                }
            }
        }
        .glassCard()
    }

    private func planetGlyph(_ planet: Planet) -> String {
        switch planet {
        case .sun:     "☉"
        case .moon:    "☽"
        case .mercury: "☿"
        case .venus:   "♀"
        case .mars:    "♂"
        case .jupiter: "♃"
        case .saturn:  "♄"
        case .uranus:  "⛢"
        case .neptune: "♆"
        case .pluto:   "♇"
        default:       "·"
        }
    }

    // MARK: - Retrograde Durumu

    private var retrogradeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.backward.circle")
                    .foregroundStyle(.red)
                Text("Aktif Retrogradlar")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(activeRetrogrades) { retro in
                HStack(spacing: 10) {
                    Text(retro.planet.name.prefix(2))
                        .font(.caption.bold())
                        .foregroundStyle(AstroTheme.accent)
                        .frame(width: 28)
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
                }
            }
        }
        .glassCard()
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
                HStack(spacing: 0) {
                    if let sun = chart.sunSign {
                        bigThreeItem(
                            label: "Güneş",
                            sign: sun,
                            icon: "sun.max.fill",
                            color: .orange
                        )
                    }
                    if let moon = chart.moonSign {
                        bigThreeItem(
                            label: "Ay",
                            sign: moon,
                            icon: "moon.fill",
                            color: AstroTheme.accentSecondary
                        )
                    }
                    if let asc = chart.ascendant {
                        bigThreeItem(
                            label: "Yükselen",
                            sign: asc,
                            icon: "arrow.up.circle.fill",
                            color: AstroTheme.accent
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Yardımcılar

    private func miniMood(title: String, rating: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < rating ? color : AstroTheme.surface)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bigThreeItem(label: String, sign: ZodiacSign, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
            Text(sign.glyph)
                .font(.title2)
            Text(sign.name)
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var moonPhaseIcon: String {
        switch moonPhase.phase {
        case .newMoon: "moonphase.new.moon"
        case .waxingCrescent: "moonphase.waxing.crescent"
        case .firstQuarter: "moonphase.first.quarter"
        case .waxingGibbous: "moonphase.waxing.gibbous"
        case .fullMoon: "moonphase.full.moon"
        case .waningGibbous: "moonphase.waning.gibbous"
        case .lastQuarter: "moonphase.last.quarter"
        case .waningCrescent: "moonphase.waning.crescent"
        }
    }

    private func starRating(_ rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i < rating ? .orange : AstroTheme.textTertiary)
            }
        }
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
        appState.gamification.earn(.checkMoonPhase)

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
                icon: moonPhase.phase.emoji
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
    }
}
