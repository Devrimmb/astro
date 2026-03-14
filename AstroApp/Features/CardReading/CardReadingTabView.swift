import SwiftUI

struct CardReadingTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
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
