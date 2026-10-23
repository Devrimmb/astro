import SwiftUI

struct RisingSignView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var isCalculating = false
    @State private var isUnlockedByAd = false

    private static let lastFreeKey = "rising_sign_last_free_date"

    private var hasFreeReadingToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: Self.lastFreeKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private var canCalculate: Bool {
        entitlements.hasNatalChart || hasFreeReadingToday || isUnlockedByAd
    }

    // Kaynak seçimi
    enum Source: Hashable {
        case person(UUID)
        case manual
    }
    @State private var selectedSource: Source?
    @State private var showManualEntry = false

    // Manuel giriş
    @State private var manualBirthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 12))!
    @State private var manualCountryCode = "TR"
    @State private var manualCity = "İstanbul"

    // Sonuç
    @State private var calculatedName: String?
    @State private var risingSign: ZodiacSign?
    @State private var sunSign: ZodiacSign?
    @State private var interpretation: RisingSignEntry?
    @State private var showResult = false

    private var people: [BirthData] {
        appState.birthDataStore.people
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 20) {
                    if !canCalculate && !showResult {
                        adGateSection
                    } else if !showResult {
                        inputSection
                    } else {
                        resultSection
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Yükselen Burç")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            // Varsayılan olarak aktif kişiyi seç
            if selectedSource == nil, let active = appState.birthDataStore.activePerson {
                selectedSource = .person(active.id)
            }
        }
    }

    // MARK: - Reklam Kapısı

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Image(systemName: "sunrise.fill")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.harmonik.opacity(0.8))

            VStack(spacing: 8) {
                Text("Yükselen Burç")
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Hesapla",
                description: "Yükselen burcunu tekrar hesaplamak için kısa bir reklam izle."
            ) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: - Giriş

    private var inputSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)

            Image(systemName: "sunrise.fill")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.harmonik.opacity(0.8))

            VStack(spacing: 8) {
                Text("Yükselen Burç")
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                Text("Yükselen burcun dış dünyadaki izlenimini yansıtır")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Kişi seçimi
            personPicker

            // Manuel giriş formu
            if showManualEntry {
                manualEntryForm
            }

            // Hesapla butonu
            Button {
                Task { await calculateRisingSign() }
            } label: {
                HStack(spacing: 8) {
                    if isCalculating {
                        ProgressView().tint(.white)
                    }
                    Image(systemName: "sunrise.fill")
                    Text(isCalculating ? "Hesaplanıyor..." : "Yükselen Burcunu Hesapla")
                }
                .glassButton()
            }
            .disabled(isCalculating || (selectedSource == nil && !showManualEntry))
        }
    }

    // MARK: - Kişi Seçici

    private var personPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AstroTheme.accent)
                Text("Kişi Seç")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Kayıtlı kişiler
            if !people.isEmpty {
                VStack(spacing: 8) {
                    ForEach(people) { person in
                        personRow(person)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AstroTheme.textTertiary)
                    Text("Henüz kayıtlı kişi yok")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(.vertical, 8)
            }

            // Manuel giriş butonu
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showManualEntry.toggle()
                    if showManualEntry {
                        selectedSource = .manual
                    } else if let active = appState.birthDataStore.activePerson {
                        selectedSource = .person(active.id)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AstroTheme.accent)
                    Text("Bilgileri Manuel Gir")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AstroTheme.accent)
                    Spacer()
                    Image(systemName: showManualEntry ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(.vertical, 8)
            }
        }
        .glassCard()
    }

    private func personRow(_ person: BirthData) -> some View {
        let isSelected: Bool = {
            if case .person(let id) = selectedSource { return id == person.id }
            return false
        }()

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedSource = .person(person.id)
                showManualEntry = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: person.isOwner ? "star.circle.fill" : "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AstroTheme.accent : AstroTheme.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(person.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        if person.isOwner {
                            Text("Ben")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AstroTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AstroTheme.accent.opacity(0.15), in: .capsule)
                        }
                    }
                    Text(person.cityName)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textTertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AstroTheme.accent : AstroTheme.textTertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                isSelected ? AstroTheme.accent.opacity(0.1) : Color.clear,
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AstroTheme.accent.opacity(0.4) : AstroTheme.cardBorder, lineWidth: 1)
            }
        }
    }

    // MARK: - Manuel Giriş Formu

    private var manualEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundStyle(AstroTheme.accent)
                Text("Doğum Bilgileri")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Doğum Tarihi ve Saati")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                DatePicker(
                    "",
                    selection: $manualBirthDate,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(AstroTheme.accent)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
                .colorScheme(.dark)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Doğum saati yükselen burç hesabı için çok önemlidir")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.harmonik.opacity(0.8))
            }

            LocationPickerView(
                selectedCountryCode: $manualCountryCode,
                selectedCity: $manualCity
            )
        }
        .glassCard()
    }

    // MARK: - Sonuç

    private var resultSection: some View {
        VStack(spacing: 20) {
            if let rising = risingSign, let sun = sunSign {
                // Başlık kartı
                VStack(spacing: 16) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AstroTheme.harmonik.opacity(0.8))

                    // Kişi adı
                    if let name = calculatedName {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AstroTheme.accent)
                    }

                    // Yükselen burç
                    VStack(spacing: 4) {
                        Text("Yükselen Burcun")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                        Text(rising.glyph)
                            .font(.system(size: 48))
                        Text(rising.name)
                            .font(.title2)
                    .fontDesign(.serif)
                            .foregroundStyle(.white)
                    }

                    // Element bilgileri
                    HStack(spacing: 16) {
                        elementBadge(label: "Yükselen", element: interpretation?.risingElement ?? rising.element.displayName)
                        elementBadge(label: "Güneş", element: interpretation?.sunElement ?? sun.element.displayName)
                    }

                    // Güneş burcu
                    HStack(spacing: 8) {
                        Text(sun.glyph)
                            .font(.title3)
                        Text("Güneş: \(sun.name)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AstroTheme.cardBorder, lineWidth: 1)
                }

                // Yorum
                if let entry = interpretation {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "sunrise.fill")
                                .foregroundStyle(AstroTheme.harmonik)
                            Text(entry.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                        }

                        MarkdownTextView(entry.description)
                    }
                    .glassCard()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "text.badge.plus")
                            .font(.title2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text("Bu kombinasyon için henüz yorum eklenmedi.")
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    .padding(.top, 20)
                }

                // Tekrar hesapla
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        showResult = false
                        risingSign = nil
                        sunSign = nil
                        interpretation = nil
                        calculatedName = nil
                    }
                } label: {
                    Label("Tekrar Hesapla", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AstroTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AstroTheme.surface, in: .capsule)
                        .overlay {
                            Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1)
                        }
                }
            } else {
                // Hesaplanamadı
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(AstroTheme.harmonik)
                    Text("Yükselen burç hesaplanamadı")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Yükselen burç hesabı için doğum saati ve yeri gereklidir. Önce doğum haritanızı hesaplatın.")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .glassCard()

                Button {
                    withAnimation { showResult = false }
                } label: {
                    Text("Geri Dön")
                        .glassButton()
                }
            }
        }
    }

    // MARK: - Yardımcılar

    private func elementBadge(label: String, element: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
            Text(element)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AstroTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(AstroTheme.accent.opacity(0.12), in: .capsule)
        }
    }

    // MARK: - Hesaplama

    private func calculateRisingSign() async {
        isCalculating = true

        let chart: BirthChart?
        var personName: String?

        switch selectedSource {
        case .person(let id):
            if let person = people.first(where: { $0.id == id }) {
                personName = person.name
                let coords = WorldCityStore.coordinates(for: person.cityName, countryCode: "TR")
                let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
                chart = await appState.ephemeris.calculateBirthChart(
                    date: person.birthDate,
                    latitude: person.latitude,
                    longitude: person.longitude,
                    timeZone: tz
                )
            } else {
                chart = nil
            }
        case .manual:
            let coords = WorldCityStore.coordinates(for: manualCity, countryCode: manualCountryCode)
            let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
            chart = await appState.ephemeris.calculateBirthChart(
                date: manualBirthDate,
                latitude: coords.lat,
                longitude: coords.lon,
                timeZone: tz
            )
        case nil:
            chart = nil
        }

        isCalculating = false

        guard let chart, let ascendant = chart.ascendant, let sun = chart.sunSign else {
            withAnimation { showResult = true }
            return
        }

        calculatedName = personName
        risingSign = ascendant
        sunSign = sun
        interpretation = RisingSignInterpretation.interpretation(rising: ascendant, sun: sun)

        // Ücretsiz hakkı tüket
        if hasFreeReadingToday {
            UserDefaults.standard.set(Date.now, forKey: Self.lastFreeKey)
        }

        withAnimation(.spring(duration: 0.5)) {
            showResult = true
        }
    }
}
