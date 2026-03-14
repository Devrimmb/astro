import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var name = ""
    @State private var birthDate = Calendar.current.date(
        from: DateComponents(year: 1990, month: 6, day: 15, hour: 12)
    )!
    @State private var birthCountryCode = "TR"
    @State private var birthCity = "İstanbul"
    @State private var isCalculating = false
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                birthInfoPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sayfa 1: Hoşgeldin

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(AstroTheme.accent)

            Text("Yıldızlar Seni Bekliyor")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Doğum haritanı keşfet, tarot kartlarını çek\nve kozmik rehberini dinle.")
                .font(.body)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Başla")
                    .glassButton()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Sayfa 2: Doğum Bilgileri

    private var birthInfoPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Doğum Bilgilerin")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Haritanı hesaplamak için bilgilerini gir.")
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adın")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                        TextField("", text: $name, prompt: Text("İsim").foregroundStyle(AstroTheme.textTertiary))
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Doğum Tarihi ve Saati")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                        DatePicker(
                            "",
                            selection: $birthDate,
                            in: ...Date.now,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(AstroTheme.accent)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
                    }

                    LocationPickerView(
                        selectedCountryCode: $birthCountryCode,
                        selectedCity: $birthCity
                    )
                }
                .glassCard()

                Text("Bu uygulama eğlence amaçlıdır.\nProfesyonel danışmanlık yerine geçmez.")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await completeOnboarding() }
                } label: {
                    HStack(spacing: 8) {
                        if isCalculating {
                            ProgressView().tint(.white)
                        }
                        Text(isCalculating ? "Hesaplanıyor..." : "Haritamı Hesapla")
                    }
                    .glassButton()
                }
                .disabled(isCalculating)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .padding(.horizontal)
        }
    }

    private func completeOnboarding() async {
        let coords = WorldCityStore.coordinates(for: birthCity, countryCode: birthCountryCode)
        isCalculating = true

        let tz = TimeZone(identifier: coords.tz) ?? TimeZone(identifier: "Europe/Istanbul")!
        let chart = await appState.ephemeris.calculateBirthChart(
            date: birthDate,
            latitude: coords.lat,
            longitude: coords.lon,
            timeZone: tz
        )
        appState.currentChart = chart
        appState.birthDataStore.save(BirthData(
            name: name,
            birthDate: birthDate,
            cityName: birthCity,
            latitude: coords.lat,
            longitude: coords.lon
        ))
        appState.syncWidgetData()

        isCalculating = false
        onComplete()
    }
}
