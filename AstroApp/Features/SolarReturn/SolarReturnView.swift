import SwiftUI

struct SolarReturnView: View {
    @Environment(AppState.self) private var appState
    @State private var natalChart: BirthChart?
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var solarReturn: SolarReturn?
    @State private var isLoading = false
    @State private var personName = ""

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
                            yearSelector
                            if isLoading {
                                ProgressView("Hesaplanıyor...")
                                    .tint(AstroTheme.accent)
                                    .foregroundStyle(AstroTheme.textSecondary)
                                    .padding(.top, 40)
                            } else if let sr = solarReturn {
                                returnDateCard(sr)
                                ChartWheelView(chart: sr.chart, size: 340)
                                    .glassCard()
                                returnBigThreeCard(sr)
                                returnPlanetsCard(sr)

                                // Paylaş
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

                            // Farklı kişi ile hesapla
                            Button {
                                natalChart = nil
                                solarReturn = nil
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
            }
            .navigationTitle("Güneş Dönüşü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedYear) { Task { await loadSolarReturn() } }
        }
    }

    // MARK: - Kişi Seçimi

    private var personSelectionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Güneş Dönüşü")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Yıllık Solar Return haritanız")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(.top, 20)

                PersonSelectionCard(
                    title: "Kişi Seçin",
                    buttonTitle: "Solar Return Hesapla",
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

    // MARK: - Return Date Card

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

    // MARK: - Big Three

    private func returnBigThreeCard(_ sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yıllık Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                bigThreeItem(
                    title: "SR Yükselen",
                    sign: sr.returnAscendant,
                    color: AstroTheme.accent,
                    description: "Yılın genel tonu"
                )
                bigThreeItem(
                    title: "SR Ay",
                    sign: sr.returnMoonSign,
                    color: .cyan,
                    description: "Duygusal tema"
                )
                bigThreeItem(
                    title: "SR Güneş",
                    sign: sr.chart.sunSign,
                    color: .orange,
                    description: "Temel enerji"
                )
            }
        }
        .glassCard()
    }

    private func bigThreeItem(title: String, sign: ZodiacSign?, color: Color, description: String) -> some View {
        VStack(spacing: 4) {
            Text(sign?.glyph ?? "?")
                .font(.title2)
            Text(sign?.name ?? "—")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
            Text(description)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Planets

    private func returnPlanetsCard(_ sr: SolarReturn) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gezegen Konumları")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(sr.chart.planets, id: \.planet) { pos in
                HStack(spacing: 8) {
                    Text(pos.planet.rawValue)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .frame(width: 80, alignment: .leading)

                    Text(pos.sign.glyph)
                        .font(.caption)

                    Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                        .font(.caption.bold())
                        .foregroundStyle(.white)

                    Spacer()

                    Text("\(pos.house). ev")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)

                    if pos.isRetrograde {
                        Text("℞")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                if pos.planet != sr.chart.planets.last?.planet {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
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
}
