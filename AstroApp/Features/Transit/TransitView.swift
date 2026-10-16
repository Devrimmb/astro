import SwiftUI

struct TransitView: View {
    @Environment(AppState.self) private var appState
    @State private var natalChart: BirthChart?
    @State private var transitReport: TransitReport?
    @State private var selectedDate: Date = .now
    @State private var isLoading = false
    @State private var personName = ""
    @State private var expandedAspects: Set<UUID> = []
    @State private var expandedPlanets: Set<Planet> = []

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                if natalChart == nil {
                    personSelectionView
                } else if let report = transitReport {
                    transitContent(report)
                } else {
                    ProgressView()
                        .tint(AstroTheme.accent)
                }
            }
            .navigationTitle("Transitler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedDate) { Task { await loadTransits() } }
        }
    }

    // MARK: - Kişi Seçimi

    private var personSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Transitler")
                        .font(.largeTitle)
                        .fontDesign(.serif)
                        .foregroundStyle(.white)
                    Text("Gezegen hareketlerinin haritanıza etkisi")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(.top, 20)

                PersonSelectionCard(
                    title: "Kişi Seçin",
                    buttonTitle: "Transit Hesapla",
                    buttonIcon: "arrow.triangle.2.circlepath"
                ) { birthData in
                    Task { await calculateForPerson(birthData) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Transit Content

    private func transitContent(_ report: TransitReport) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                weekStrip
                if let chart = natalChart {
                    VStack(spacing: 6) {
                        TransitBiWheelView(
                            natalChart: chart,
                            transitPositions: report.transitPositions,
                            size: 340
                        )
                        HStack(spacing: 14) {
                            wheelLegend(color: .white, text: "İç: natal")
                            wheelLegend(color: AstroTheme.accentSecondary, text: "Dış: \(shortDateText(selectedDate))")
                        }
                    }
                    .glassCard()
                }
                currentPositionsCard(report)
                if !report.significantTransits.isEmpty {
                    significantTransitsCard(report)
                }
                transitListCard(report)

                // Paylaş
                Button {
                    ShareImageRenderer.shareTransit(
                        personName: personName,
                        date: selectedDate,
                        report: report
                    )
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Paylaş")
                    }
                    .glassButton()
                }

                // Farklı kişi ile hesapla
                Button {
                    natalChart = nil
                    transitReport = nil
                } label: {
                    Label("Farklı Kişi Seç", systemImage: "person.2")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AstroTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AstroTheme.surface, in: .capsule)
                        .overlay {
                            Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1)
                        }
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
    }

    // MARK: - Hafta Şeridi

    /// Seçili günü ortalayan 7 günlük şerit; oklar haftayı kaydırır.
    private var weekStrip: some View {
        let calendar = Calendar.current
        let days = (-3...3).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedDate) }

        return VStack(spacing: 8) {
            HStack {
                Button {
                    selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left").font(.caption.weight(.semibold))
                }
                Spacer()
                Text(monthYearText(selectedDate))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if !isToday {
                    Button("Bugün") { selectedDate = .now }
                        .font(.caption.weight(.semibold))
                }
                Button {
                    selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
            }
            .foregroundStyle(AstroTheme.accent)

            HStack(spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let selected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let today = calendar.isDateInToday(day)
                    Button {
                        selectedDate = day
                    } label: {
                        VStack(spacing: 2) {
                            Text(weekdayText(day).uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .kerning(0.8)
                                .foregroundStyle(selected ? .white.opacity(0.8) : AstroTheme.textTertiary)
                            Text("\(calendar.component(.day, from: day))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selected ? .white : AstroTheme.textSecondary)
                            Circle()
                                .fill(today ? AstroTheme.accentSecondary : .clear)
                                .frame(width: 3, height: 3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AstroTheme.accent.opacity(0.35))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(AstroTheme.accent.opacity(0.5), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(fullDateText(day))
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
        }
        .glassCard(cornerRadius: 16, padding: 12)
        .sensoryFeedback(.selection, trigger: selectedDate)
    }

    private func wheelLegend(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.caption2).foregroundStyle(AstroTheme.textTertiary)
        }
    }

    private func monthYearText(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "tr_TR"); f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func weekdayText(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "tr_TR"); f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func shortDateText(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "tr_TR"); f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }

    private func fullDateText(_ date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "tr_TR"); f.dateFormat = "d MMMM yyyy, EEEE"
        return f.string(from: date)
    }

    // MARK: - Current Positions

    private func currentPositionsCard(_ report: TransitReport) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "globe.americas")
                    .foregroundStyle(AstroTheme.accent)
                Text("Güncel Gezegen Konumları")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Ev geçişi için dokun")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .padding(.bottom, 4)

            ForEach(report.transitPositions, id: \.planet) { pos in
                positionRow(pos)
                if pos.planet != report.transitPositions.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    private func positionRow(_ pos: PlanetPosition) -> some View {
        let isExpanded = expandedPlanets.contains(pos.planet)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                PlanetRow(position: pos)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            if isExpanded,
               let interp = DailyCosmicCoach.houseTransitInterpretation(planet: pos.planet, house: pos.house) {
                Text(interp.message)
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 28)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded { expandedPlanets.remove(pos.planet) }
                else { expandedPlanets.insert(pos.planet) }
            }
        }
    }

    // MARK: - Significant Transits

    private func significantTransitsCard(_ report: TransitReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AstroTheme.planet(.sun))
                Text("Önemli Transitler")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(report.significantTransits.prefix(5)) { aspect in
                transitRow(aspect)
            }
        }
        .glassCard()
    }

    // MARK: - Full Transit List

    private func transitListCard(_ report: TransitReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(AstroTheme.accent)
                Text("Tüm Transitler (\(report.aspects.count))")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            if report.aspects.isEmpty {
                Text("Bu tarihte aktif transit bulunmuyor.")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                let harmonious = report.harmoniousTransits
                let challenging = report.challengingTransits
                let neutral = report.aspects.filter { $0.type.nature == .notr }

                if !harmonious.isEmpty {
                    sectionHeader("Uyumlu Transitler", color: AstroTheme.harmonik)
                    ForEach(harmonious) { aspect in
                        transitRow(aspect)
                    }
                }

                if !challenging.isEmpty {
                    sectionHeader("Zorlayıcı Transitler", color: AstroTheme.zorlayici)
                    ForEach(challenging) { aspect in
                        transitRow(aspect)
                    }
                }

                if !neutral.isEmpty {
                    sectionHeader("Kavuşumlar", color: AstroTheme.accent)
                    ForEach(neutral) { aspect in
                        transitRow(aspect)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.top, 4)
    }

    private func transitRow(_ aspect: TransitAspect) -> some View {
        let isExpanded = expandedAspects.contains(aspect.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                AspectRow(aspect)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            if isExpanded {
                Text(DailyCosmicCoach.aspectInterpretation(aspect, today: isToday).message)
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 62)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded { expandedAspects.remove(aspect.id) }
                else { expandedAspects.insert(aspect.id) }
            }
        }
    }

    private func aspectColor(_ type: AspectType) -> Color {
        AstroTheme.nature(type.nature)
    }

    // MARK: - Data Loading

    private func calculateForPerson(_ data: BirthData) async {
        personName = data.name
        isLoading = true
        let chart = await appState.ephemeris.calculateBirthChart(
            date: data.birthDate,
            latitude: data.latitude,
            longitude: data.longitude,
            timeZone: TimeZone(identifier: "Europe/Istanbul")!
        )
        natalChart = chart
        await loadTransits()
    }

    private func loadTransits() async {
        guard let chart = natalChart else { return }
        isLoading = true
        transitReport = appState.ephemeris.calculateTransits(for: chart, date: selectedDate)
        isLoading = false
    }
}
