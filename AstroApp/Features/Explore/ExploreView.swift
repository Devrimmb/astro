import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Astroloji
                        sectionHeader(title: "Astroloji", icon: "star.circle.fill", color: AstroTheme.accent)

                        featureCard(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Transitler",
                            description: "Güncel gezegen hareketlerinin doğum haritanıza etkisi",
                            color: AstroTheme.accent,
                            destination: TransitView()
                        )

                        featureCard(
                            icon: "sun.max.circle",
                            title: "Güneş Dönüşü",
                            description: "Yıllık Solar Return haritanız — yılın enerjisini keşfedin",
                            color: .orange,
                            destination: SolarReturnView()
                        )

                        featureCard(
                            icon: "heart.text.square",
                            title: "Synastry Analizi",
                            description: "İki harita karşılaştırması ile gerçek ilişki uyumu",
                            color: AstroTheme.zorlayici,
                            destination: SynastryView()
                        )

                        featureCard(
                            icon: "arrow.triangle.merge",
                            title: "Composite Harita",
                            description: "İki haritanın orta noktalarından ilişki haritası",
                            color: .mint,
                            destination: CompositeChartView()
                        )

                        featureCard(
                            icon: "moon.stars",
                            title: "Ay Fazları",
                            description: "Güncel ay fazı, ay burcu ve enerji rehberi",
                            color: .cyan,
                            destination: MoonPhaseView()
                        )

                        featureCard(
                            icon: "moon.haze",
                            title: "Ay Boşlukta (VOC)",
                            description: "Void of Course Moon — karar almak için uygun olmayan zamanlar",
                            color: Color(red: 0.6, green: 0.5, blue: 0.8),
                            destination: VoidOfCourseView()
                        )

                        featureCard(
                            icon: "arrow.backward.circle",
                            title: "Retrograde Takvimi",
                            description: "Gezegen retrograde dönemleri takvimi",
                            color: .red,
                            destination: RetrogradeCalendarView()
                        )

                        featureCard(
                            icon: "circle.lefthalf.striped.horizontal",
                            title: "Tutulmalar",
                            description: "Güneş ve Ay tutulma tarihleri ve etkileri",
                            color: .indigo,
                            destination: EclipseView()
                        )

                        featureCard(
                            icon: "clock.fill",
                            title: "Gezegen Saatleri",
                            description: "Günün her saatinin yönetici gezegeni",
                            color: .brown,
                            destination: PlanetaryHoursView()
                        )

                        featureCard(
                            icon: "sparkle",
                            title: "Sabit Yıldızlar",
                            description: "Regulus, Sirius, Algol ve diğer önemli sabit yıldızlar",
                            color: .yellow,
                            destination: FixedStarsView()
                        )

                        // MARK: - Kart Falları
                        sectionHeader(title: "Kart Falları", icon: "sparkles", color: .purple)

                        featureCard(
                            icon: "sparkles",
                            title: "Tarot",
                            description: "Günlük tarot kartı çekin ve yorumunu okuyun",
                            color: .purple,
                            destination: TarotView()
                        )
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
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
