import SwiftUI

struct AstrologyTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        chartHeroCard

                        // MARK: - Bilgi Bandı
                        astrologyInfoBanner

                        // MARK: - Doğum Haritası
                        sectionHeader(title: "Doğum Haritası", icon: "star.circle.fill", color: AstroTheme.accent)

                        featureCard(
                            icon: "star.circle.fill",
                            title: "Doğum Haritası Hesapla",
                            description: "Doğum bilgilerinizle kişisel yıldız haritanızı oluşturun",
                            color: AstroTheme.accent
                        ) { BirthChartInputView() }

                        featureCard(
                            icon: "sunrise.fill",
                            title: "Yükselen Burç Yorumu",
                            description: "Yükselen burcun ve güneş burcunun birleşik etkisi",
                            color: AstroTheme.harmonik
                        ) { RisingSignView() }

                        featureCard(
                            icon: "moon.fill",
                            title: "Ay Burcu Yorumu",
                            description: "Ay burcunun duygusal dünyandaki etkisini keşfet",
                            color: AstroTheme.planet(.moon)
                        ) { MoonSignView() }

                        // MARK: - Günlük & Dönemsel
                        sectionHeader(title: "Günlük & Dönemsel", icon: "sun.horizon", color: AstroTheme.planet(.sun))

                        featureCard(
                            icon: "sun.horizon",
                            title: "Günlük Burç Yorumu",
                            description: "Bugünün enerjisi ve burç yorumunuz",
                            color: AstroTheme.planet(.sun)
                        ) { DailyHoroscopeView() }

                        featureCard(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Transitler",
                            description: "Güncel gezegen hareketlerinin doğum haritanıza etkisi",
                            color: AstroTheme.accent
                        ) { TransitView() }

                        featureCard(
                            icon: "sun.max.circle",
                            title: "Güneş Dönüşü",
                            description: "Yıllık Solar Return haritanız — yılın enerjisini keşfedin",
                            color: AstroTheme.air
                        ) { SolarReturnView() }

                        // MARK: - Uyum & İlişkiler
                        sectionHeader(title: "Uyum & İlişkiler", icon: "heart.text.square", color: AstroTheme.planet(.venus))

                        featureCard(
                            icon: "heart.text.square",
                            title: "Synastry Analizi",
                            description: "İki harita karşılaştırması ile gerçek ilişki uyumu",
                            color: AstroTheme.planet(.venus)
                        ) { SynastryView() }

                        featureCard(
                            icon: "arrow.triangle.merge",
                            title: "Composite Harita",
                            description: "İki haritanın orta noktalarından ilişki haritası",
                            color: AstroTheme.harmonik
                        ) { CompositeChartView() }

                        // MARK: - Takvim
                        sectionHeader(title: "Takvim", icon: "calendar", color: AstroTheme.accentSecondary)

                        featureCard(
                            icon: "calendar.badge.clock",
                            title: "Astro Takvim",
                            description: "Ay fazları, retrograde, tutulma ve VOC — tek takvimde",
                            color: AstroTheme.accentSecondary
                        ) { AstroCalendarContent() }

                        // MARK: - Ay & Gök Olayları
                        sectionHeader(title: "Ay & Gök Olayları", icon: "moon.stars", color: AstroTheme.water)

                        featureCard(
                            icon: "moon.stars",
                            title: "Ay Fazları",
                            description: "Güncel ay fazı, ay burcu ve enerji rehberi",
                            color: AstroTheme.planet(.moon)
                        ) { MoonPhaseView() }

                        featureCard(
                            icon: "moon.haze",
                            title: "Ay Boşlukta (VOC)",
                            description: "Void of Course Moon — karar almak için uygun olmayan zamanlar",
                            color: AstroTheme.water
                        ) { VoidOfCourseView() }

                        featureCard(
                            icon: "arrow.backward.circle",
                            title: "Retrograde Takvimi",
                            description: "Gezegen retrograde dönemleri takvimi",
                            color: AstroTheme.zorlayici
                        ) { RetrogradeCalendarView() }

                        featureCard(
                            icon: "circle.lefthalf.striped.horizontal",
                            title: "Tutulmalar",
                            description: "Güneş ve Ay tutulma tarihleri ve etkileri",
                            color: AstroTheme.accent
                        ) { EclipseView() }

                        featureCard(
                            icon: "clock.fill",
                            title: "Gezegen Saatleri",
                            description: "Günün her saatinin yönetici gezegeni",
                            color: AstroTheme.planet(.saturn)
                        ) { PlanetaryHoursView() }

                        featureCard(
                            icon: "sparkle",
                            title: "Sabit Yıldızlar",
                            description: "Regulus, Sirius, Algol ve diğer önemli sabit yıldızlar",
                            color: AstroTheme.air
                        ) { FixedStarsView() }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Astroloji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Doğum Haritan (hero)

    /// Harita varsa sonuç ekranına kestirme; yoksa hesaplamaya çağrı.
    @ViewBuilder
    private var chartHeroCard: some View {
        if let chart = appState.currentChart {
            let name = appState.birthDataStore.savedData?.name ?? ""
            NavigationLink {
                BirthChartResultView(chart: chart, personName: name.isEmpty ? "Haritam" : name)
                    .environment(appState)
                    .environment(appState.store)
                    .environment(appState.entitlements)
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(.white.opacity(0.14), lineWidth: 1)
                        Circle().stroke(.white.opacity(0.08), lineWidth: 1).padding(7)
                        if let sun = chart.sunSign {
                            Text(sun.glyph)
                                .font(.system(size: 20, design: .serif))
                                .foregroundStyle(AstroTheme.element(sun.element))
                        }
                        Circle().fill(AstroTheme.planet(.sun)).frame(width: 5, height: 5).offset(y: -26)
                        Circle().fill(AstroTheme.planet(.moon)).frame(width: 4, height: 4).offset(x: 20, y: 17)
                        Circle().fill(AstroTheme.harmonik).frame(width: 4, height: 4).offset(x: -21, y: 15)
                    }
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Doğum Haritan")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(heroSubtitle(name: name, chart: chart))
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.accent)
                }
                .glassCard(tint: AstroTheme.accent)
            }
        } else {
            NavigationLink {
                BirthChartInputView()
                    .environment(appState)
                    .environment(appState.store)
                    .environment(appState.entitlements)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "star.circle.fill")
                        .font(.title)
                        .foregroundStyle(AstroTheme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Doğum haritanı oluştur")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Tüm yorumlar ve transitler haritana göre kişiselleşir.")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.accent)
                }
                .glassCard(tint: AstroTheme.accent)
            }
        }
    }

    private func heroSubtitle(name: String, chart: BirthChart) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM yyyy"
        var parts: [String] = []
        if !name.isEmpty { parts.append(name) }
        parts.append(f.string(from: chart.birthDate))
        if let city = appState.birthDataStore.savedData?.cityName, !city.isEmpty { parts.append(city) }
        return parts.joined(separator: " · ")
    }

    // MARK: - Bilgi Bandı

    @AppStorage("astrology_info_dismissed") private var astrologyInfoDismissed = false

    @ViewBuilder
    private var astrologyInfoBanner: some View {
        if !astrologyInfoDismissed {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(AstroTheme.accent)
                    Text("Astroloji Rehberi")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation { astrologyInfoDismissed = true }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    astroInfoLine(icon: "star.circle.fill", text: "Doğum haritanı hesaplatarak tüm özellikleri aç")
                    astroInfoLine(icon: "sunrise.fill", text: "Yükselen ve Ay burcu için doğum saatin gerekli")
                    astroInfoLine(icon: "sun.horizon", text: "Günlük burcun her gün güncellenir")
                    astroInfoLine(icon: "gift.fill", text: "Günde 1 ücretsiz yorum hakkın var")
                }
            }
            .glassCard()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func astroInfoLine(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AstroTheme.accent)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .kerning(1.2)
                .foregroundStyle(AstroTheme.textTertiary)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Feature Card

    private func featureCard<Destination: View>(
        icon: String,
        title: String,
        description: String,
        color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
                .environment(appState)
                .environment(appState.store)
                .environment(appState.entitlements)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.14), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .glassCard(cornerRadius: 16, padding: 12)
        }
    }
}
