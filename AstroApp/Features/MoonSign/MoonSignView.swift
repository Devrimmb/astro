import SwiftUI

struct MoonSignView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var selectedGender: Gender = .women
    @State private var useManualEntry = false
    @State private var isCalculating = false
    @State private var isUnlockedByAd = false

    // Manuel giriş
    @State private var manualName = ""
    @State private var manualBirthDate = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 12))!
    @State private var manualCountryCode = "TR"
    @State private var manualCity = "İstanbul"

    // Sonuç
    @State private var moonSign: ZodiacSign?
    @State private var interpretation: MoonSignEntry?
    @State private var showResult = false

    private static let lastFreeKey = "moon_sign_last_free_date"

    private var hasFreeReadingToday: Bool {
        guard let last = UserDefaults.standard.object(forKey: Self.lastFreeKey) as? Date else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private var canCalculate: Bool {
        entitlements.hasNatalChart || hasFreeReadingToday || isUnlockedByAd
    }

    enum Gender: String, CaseIterable {
        case women = "women"
        case men = "men"

        var displayName: String {
            switch self {
            case .women: "Kadın"
            case .men: "Erkek"
            }
        }

        var icon: String {
            switch self {
            case .women: "figure.stand.dress"
            case .men: "figure.stand"
            }
        }
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
        .navigationTitle("Ay Burcu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Reklam Kapısı

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Image(systemName: "moon.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow.opacity(0.8))

            VStack(spacing: 8) {
                Text("Ay Burcu")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Hesapla",
                description: "Ay burcunu tekrar hesaplamak için kısa bir reklam izle veya Pro'ya geç."
            ) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: - Giriş

    private var inputSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)

            Image(systemName: "moon.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow.opacity(0.8))

            VStack(spacing: 8) {
                Text("Ay Burcu")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Ay burcun duygusal dünyanı yansıtır")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            // Cinsiyet seçimi
            genderPicker

            // Kaynak seçimi: Haritamdan / Başka biri
            sourceToggle

            // Manuel giriş formu
            if useManualEntry {
                manualEntryForm
            }

            // Hesapla butonu
            Button {
                Task { await calculateMoonSign() }
            } label: {
                HStack(spacing: 8) {
                    if isCalculating {
                        ProgressView().tint(.white)
                    }
                    Image(systemName: "moon.stars.fill")
                    Text(isCalculating ? "Hesaplanıyor..." : "Ay Burcunu Hesapla")
                }
                .glassButton()
            }
            .disabled(isCalculating)
        }
    }

    // MARK: - Cinsiyet Seçici

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cinsiyet")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)

            HStack(spacing: 12) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedGender = gender
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: gender.icon)
                            Text(gender.displayName)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedGender == gender ? .white : AstroTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selectedGender == gender
                                ? AstroTheme.accent.opacity(0.3)
                                : AstroTheme.surface,
                            in: .rect(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selectedGender == gender ? AstroTheme.accent.opacity(0.5) : AstroTheme.cardBorder,
                                    lineWidth: 1
                                )
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Kaynak Toggle

    private var sourceToggle: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.3)) { useManualEntry = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                    Text("Haritamdan")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(!useManualEntry ? .white : AstroTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    !useManualEntry ? AstroTheme.accent.opacity(0.3) : AstroTheme.surface,
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(!useManualEntry ? AstroTheme.accent.opacity(0.5) : AstroTheme.cardBorder, lineWidth: 1)
                }
            }

            Button {
                withAnimation(.spring(duration: 0.3)) { useManualEntry = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                    Text("Başka Biri")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(useManualEntry ? .white : AstroTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    useManualEntry ? AstroTheme.accent.opacity(0.3) : AstroTheme.surface,
                    in: .rect(cornerRadius: 12)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(useManualEntry ? AstroTheme.accent.opacity(0.5) : AstroTheme.cardBorder, lineWidth: 1)
                }
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
                Text("Ad")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                TextField("", text: $manualName, prompt: Text("İsim").foregroundStyle(AstroTheme.textTertiary))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 10))
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
            if let sign = moonSign {
                // Ay burcu başlığı
                VStack(spacing: 12) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.yellow.opacity(0.8))

                    Text(sign.glyph)
                        .font(.system(size: 56))

                    Text("Ay Burcu: \(sign.name)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    if let entry = interpretation {
                        Text("\(entry.element) Elementi")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AstroTheme.accent.opacity(0.12), in: .capsule)
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
                            Image(systemName: selectedGender == .women ? "figure.stand.dress" : "figure.stand")
                                .foregroundStyle(AstroTheme.accent)
                            Text("\(sign.name) \(selectedGender.displayName)")
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
                        Text("Bu ay burcu için henüz yorum eklenmedi.")
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                    .padding(.top, 20)
                }

                // Tekrar hesapla
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        showResult = false
                        moonSign = nil
                        interpretation = nil
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
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("Ay burcu hesaplanamadı")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Önce doğum bilgilerinizi girerek haritanızı hesaplatın.")
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

    // MARK: - Hesaplama

    private func calculateMoonSign() async {
        isCalculating = true

        let sign: ZodiacSign?

        if useManualEntry {
            // Manuel giriş: doğum bilgileriyle harita hesapla
            let coords = WorldCityStore.coordinates(for: manualCity, countryCode: manualCountryCode)
            let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
            let chart = await appState.ephemeris.calculateBirthChart(
                date: manualBirthDate,
                latitude: coords.lat,
                longitude: coords.lon,
                timeZone: tz
            )
            sign = chart.moonSign
        } else {
            // Mevcut haritadan
            sign = appState.currentChart?.moonSign
        }

        isCalculating = false

        guard let moonResult = sign else {
            withAnimation { showResult = true }
            return
        }

        moonSign = moonResult
        interpretation = MoonSignInterpretation.interpretation(sign: moonResult, gender: selectedGender.rawValue)

        // Ücretsiz hakkı tüket
        if hasFreeReadingToday {
            UserDefaults.standard.set(Date.now, forKey: Self.lastFreeKey)
        }

        withAnimation(.spring(duration: 0.5)) {
            showResult = true
        }
    }
}
