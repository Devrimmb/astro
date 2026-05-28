import SwiftUI

struct AstrologyTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
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
                            color: .orange
                        ) { RisingSignView() }

                        featureCard(
                            icon: "moon.fill",
                            title: "Ay Burcu Yorumu",
                            description: "Ay burcunun duygusal dünyandaki etkisini keşfet",
                            color: .yellow
                        ) { MoonSignView() }

                        // MARK: - Günlük & Dönemsel
                        sectionHeader(title: "Günlük & Dönemsel", icon: "sun.horizon", color: .orange)

                        featureCard(
                            icon: "sun.horizon",
                            title: "Günlük Burç Yorumu",
                            description: "Bugünün enerjisi ve burç yorumunuz",
                            color: .orange
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
                            color: .orange
                        ) { SolarReturnView() }

                        // MARK: - Uyum & İlişkiler
                        sectionHeader(title: "Uyum & İlişkiler", icon: "heart.text.square", color: .pink)

                        featureCard(
                            icon: "heart.text.square",
                            title: "Synastry Analizi",
                            description: "İki harita karşılaştırması ile gerçek ilişki uyumu",
                            color: AstroTheme.zorlayici
                        ) { SynastryView() }

                        featureCard(
                            icon: "arrow.triangle.merge",
                            title: "Composite Harita",
                            description: "İki haritanın orta noktalarından ilişki haritası",
                            color: .mint
                        ) { CompositeChartView() }

                        // MARK: - Takvim
                        sectionHeader(title: "Takvim", icon: "calendar", color: .blue)

                        featureCard(
                            icon: "calendar.badge.clock",
                            title: "Astro Takvim",
                            description: "Ay fazları, retrograde, tutulma ve VOC — tek takvimde",
                            color: .blue
                        ) { AstroCalendarContent() }

                        // MARK: - Ay & Gök Olayları
                        sectionHeader(title: "Ay & Gök Olayları", icon: "moon.stars", color: .cyan)

                        featureCard(
                            icon: "moon.stars",
                            title: "Ay Fazları",
                            description: "Güncel ay fazı, ay burcu ve enerji rehberi",
                            color: .cyan
                        ) { MoonPhaseView() }

                        featureCard(
                            icon: "moon.haze",
                            title: "Ay Boşlukta (VOC)",
                            description: "Void of Course Moon — karar almak için uygun olmayan zamanlar",
                            color: Color(red: 0.6, green: 0.5, blue: 0.8)
                        ) { VoidOfCourseView() }

                        featureCard(
                            icon: "arrow.backward.circle",
                            title: "Retrograde Takvimi",
                            description: "Gezegen retrograde dönemleri takvimi",
                            color: .red
                        ) { RetrogradeCalendarView() }

                        featureCard(
                            icon: "circle.lefthalf.striped.horizontal",
                            title: "Tutulmalar",
                            description: "Güneş ve Ay tutulma tarihleri ve etkileri",
                            color: .indigo
                        ) { EclipseView() }

                        featureCard(
                            icon: "clock.fill",
                            title: "Gezegen Saatleri",
                            description: "Günün her saatinin yönetici gezegeni",
                            color: .brown
                        ) { PlanetaryHoursView() }

                        featureCard(
                            icon: "sparkle",
                            title: "Sabit Yıldızlar",
                            description: "Regulus, Sirius, Algol ve diğer önemli sabit yıldızlar",
                            color: .yellow
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
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.top, 4)
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
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: .rect(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            .glassCard()
        }
    }
}
