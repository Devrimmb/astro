import SwiftUI

struct CardReadingTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        tarotHeroCard

                        sectionHeader(title: "Diğer Fallar", icon: "sparkles", color: AstroTheme.accent)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            readingTile(
                                glyph: "👁", title: "Katina Falı", subtitle: "Kadim aşk kartları",
                                tint: AstroTheme.planet(.venus)
                            ) { KatinaView() }
                            readingTile(
                                glyph: "ᚠ", title: "Rün Falı", subtitle: "Viking rehberliği",
                                tint: AstroTheme.planet(.saturn), serif: true
                            ) { RuneView() }
                            readingTile(
                                glyph: "⚡", title: "Tanrı Kartları", subtitle: "Mitolojik mesaj",
                                tint: AstroTheme.planet(.neptune)
                            ) { GodCardView() }
                            readingTile(
                                glyph: "✦", title: "Tarot Falı", subtitle: "3 kart açılımı",
                                tint: AstroTheme.accent, serif: true
                            ) { TarotView() }
                        }

                        // MARK: - Nasıl Çalışır
                        cardReadingInfoBanner
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

    // MARK: - Günlük Tarot (hero)

    private var tarotHeroCard: some View {
        NavigationLink {
            TarotView()
                .environment(appState)
                .environment(appState.store)
                .environment(appState.entitlements)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    // Kart arkası minyatürü
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LinearGradient(colors: [Color(red: 0.23, green: 0.16, blue: 0.48), Color(red: 0.10, green: 0.08, blue: 0.25)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AstroTheme.air.opacity(0.45), lineWidth: 1)
                        Text("☉")
                            .font(.system(size: 22, design: .serif))
                            .foregroundStyle(AstroTheme.air)
                    }
                    .frame(width: 48, height: 72)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TAROT · GÜNLÜK")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(1.2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text("Bugünün kartını çek")
                            .font(.title3)
                            .fontDesign(.serif)
                            .foregroundStyle(.white)
                        Text("Geçmiş · Şimdi · Gelecek")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }

                HStack {
                    Text("Kart Çek")
                        .glassButton()
                    Spacer()
                    Pill(text: "Günde 1 ücretsiz", color: AstroTheme.accent, icon: "gift.fill")
                }
            }
            .glassCard(tint: AstroTheme.planet(.sun))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fal Tile'ları

    private func readingTile<Destination: View>(
        glyph: String,
        title: String,
        subtitle: String,
        tint: Color,
        serif: Bool = false,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
                .environment(appState)
                .environment(appState.store)
                .environment(appState.entitlements)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(glyph)
                    .font(.system(size: 22, design: serif ? .serif : .default))
                    .foregroundStyle(tint)
                    .frame(height: 28)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 16, padding: 14, tint: tint)
        }
        .buttonStyle(.plain)
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
}
