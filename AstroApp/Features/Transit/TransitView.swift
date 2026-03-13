import SwiftUI

struct TransitView: View {
    @Environment(AppState.self) private var appState
    @State private var natalChart: BirthChart?
    @State private var transitReport: TransitReport?
    @State private var selectedDate: Date = .now
    @State private var isLoading = false
    @State private var personName = ""

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
                        .font(.largeTitle.weight(.bold))
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
                datePicker
                if let chart = natalChart {
                    TransitBiWheelView(
                        natalChart: chart,
                        transitPositions: report.transitPositions,
                        size: 340
                    )
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

    // MARK: - Date Picker

    private var datePicker: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AstroTheme.accent)
            }

            Spacer()

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .colorScheme(.dark)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AstroTheme.accent)
            }
        }
        .padding(.horizontal, 8)
        .glassCard()
    }

    // MARK: - Current Positions

    private func currentPositionsCard(_ report: TransitReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "globe.americas")
                    .foregroundStyle(AstroTheme.accent)
                Text("Güncel Gezegen Konumları")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(report.transitPositions, id: \.planet) { pos in
                    HStack(spacing: 6) {
                        Text(planetGlyph(pos.planet))
                            .font(.caption)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(pos.planet.rawValue)
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.textSecondary)
                            HStack(spacing: 3) {
                                Text(pos.sign.glyph)
                                    .font(.caption2)
                                Text("\(pos.sign.name) \(String(format: "%.0f", pos.degree))°")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                if pos.isRetrograde {
                                    Text("℞")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Significant Transits

    private func significantTransitsCard(_ report: TransitReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
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
        HStack(spacing: 8) {
            Text(planetGlyph(aspect.transitPlanet))
                .font(.caption)
                .frame(width: 18)

            Text(aspect.type.symbol)
                .font(.caption)
                .foregroundStyle(aspectColor(aspect.type))
                .frame(width: 18)

            Text(planetGlyph(aspect.natalPlanet))
                .font(.caption)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text("T.\(aspect.transitPlanet.rawValue) \(aspect.type.turkishName) N.\(aspect.natalPlanet.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(.white)
                Text("\(aspect.applying ? "Yaklaşan" : "Ayrılan") · \(String(format: "%.1f", aspect.orb))° orb")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }

            Spacer()

            Circle()
                .fill(aspectColor(aspect.type))
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 2)
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type.nature {
        case .harmonik: AstroTheme.harmonik
        case .zorlayici: AstroTheme.zorlayici
        case .notr: AstroTheme.accent
        }
    }

    private func planetGlyph(_ planet: Planet) -> String {
        switch planet {
        case .sun: "☉"
        case .moon: "☽"
        case .mercury: "☿"
        case .venus: "♀"
        case .mars: "♂"
        case .jupiter: "♃"
        case .saturn: "♄"
        case .uranus: "♅"
        case .neptune: "♆"
        case .pluto: "♇"
        case .northNode: "☊"
        case .chiron: "⚷"
        case .lilith: "⚸"
        case .partOfFortune: "⊕"
        case .ceres: "⚳"
        case .pallas: "⚴"
        case .juno: "⚵"
        case .vesta: "⚶"
        }
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
