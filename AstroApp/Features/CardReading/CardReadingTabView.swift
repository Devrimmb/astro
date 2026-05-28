import SwiftUI

struct CardReadingTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Nasıl Çalışır
                        cardReadingInfoBanner

                        // MARK: - Tarot
                        sectionHeader(title: "Tarot", icon: "sparkles", color: .purple)

                        featureCard(
                            icon: "sparkles",
                            title: "Tarot Falı",
                            description: "Geçmiş, şimdi ve gelecek — 3 kart açılımı",
                            color: .purple,
                            destination: TarotView()
                        )

                        // MARK: - Katina
                        sectionHeader(title: "Katina", icon: "eye.fill", color: .orange)

                        featureCard(
                            icon: "eye.fill",
                            title: "Katina Falı",
                            description: "Kadim katina kartları ile geleceğine bak",
                            color: .orange,
                            destination: KatinaView()
                        )

                        // MARK: - Rune
                        sectionHeader(title: "Rune", icon: "circle.grid.3x3.fill", color: .brown)

                        featureCard(
                            icon: "circle.grid.3x3.fill",
                            title: "Rune Falı",
                            description: "Kadim Viking runeleri ile rehberlik al",
                            color: .brown,
                            destination: RuneView()
                        )

                        // MARK: - Tanrı Kartları
                        sectionHeader(title: "Tanrı Kartları", icon: "bolt.fill", color: .indigo)

                        featureCard(
                            icon: "bolt.fill",
                            title: "Tanrı Kartları",
                            description: "Mitolojik tanrılardan sana özel mesaj al",
                            color: .indigo,
                            destination: GodCardView()
                        )
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Kart Falı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Bilgi Bandı

    @AppStorage("card_reading_info_dismissed") private var infoDismissed = false

    @ViewBuilder
    private var cardReadingInfoBanner: some View {
        if !infoDismissed {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundStyle(AstroTheme.accent)
                    Text("Nasıl Çalışır?")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation { infoDismissed = true }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AstroTheme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    infoLine(icon: "hand.tap.fill", text: "Yelpazeden bir kart seç ve dokun")
                    infoLine(icon: "arrow.triangle.2.circlepath", text: "Kartını çevir ve yorumunu oku")
                    infoLine(icon: "gift.fill", text: "Her gün 1 ücretsiz hak, ekstra için reklam izle")
                    infoLine(icon: "star.fill", text: "Her fal bakışında yıldız kazan!")
                }
            }
            .glassCard()
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func infoLine(icon: String, text: String) -> some View {
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
