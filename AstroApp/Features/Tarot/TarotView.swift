import SwiftUI

struct TarotView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = TarotViewModel()
    @State private var isUnlockedByAd = false

    /// Kullanıcı kart çekebilir mi?
    private var canDraw: Bool {
        entitlements.hasNatalChart || vm.hasFreeReadingToday || isUnlockedByAd
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        if vm.hasDrawn {
                            spreadView
                            if vm.allRevealed {
                                interpretationView

                                // Paylaş
                                Button {
                                    ShareImageRenderer.shareTarot(drawnCards: vm.drawnCards)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Sonucu Paylaş")
                                    }
                                    .glassButton()
                                }

                                resetButton
                            }
                        } else if canDraw {
                            introView
                        } else {
                            adGateSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Reklam Kapısı

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("✦")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.accent)

            VStack(spacing: 8) {
                Text("Tarot")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Fal Bak",
                description: "Kartları tekrar çekmek için kısa bir reklam izle veya Pro'ya geç."
            ) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: - Giriş

    private var introView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("✦")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.accent)

            VStack(spacing: 8) {
                Text("Tarot")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Geçmiş, Şimdi ve Gelecek")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            Button {
                withAnimation(.spring(duration: 0.5)) {
                    vm.drawCards()
                }
            } label: {
                Text("Kartları Çek")
                    .glassButton()
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Kart Açılımı

    private var spreadView: some View {
        HStack(spacing: 10) {
            ForEach(vm.drawnCards) { drawn in
                cardView(drawn)
            }
        }
    }

    private func cardView(_ drawn: DrawnCard) -> some View {
        VStack(spacing: 8) {
            Text(drawn.position.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AstroTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            ZStack {
                // Arka yüz
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AstroTheme.accent.opacity(0.6), AstroTheme.accentSecondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AstroTheme.cardBorder, lineWidth: 1)
                    }
                    .overlay {
                        Text("✦")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    .opacity(drawn.isRevealed ? 0 : 1)

                // Ön yüz
                VStack(spacing: 8) {
                    Text(drawn.card.image)
                        .font(.system(size: 32))

                    Text(drawn.card.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if drawn.isReversed {
                        Text("Ters")
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.zorlayici)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AstroTheme.zorlayici.opacity(0.15), in: .capsule)
                    }
                }
                .padding(8)
                .opacity(drawn.isRevealed ? 1 : 0)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .background(AstroTheme.surface, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AstroTheme.cardBorder, lineWidth: 1)
            }
            .rotation3DEffect(
                .degrees(drawn.isRevealed ? 0 : 180),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .onTapGesture {
                guard !drawn.isRevealed else { return }
                withAnimation(.spring(duration: 0.6)) {
                    vm.revealCard(drawn)
                }
            }
        }
    }

    // MARK: - Yorum

    private var interpretationView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kartların Mesajı")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(vm.drawnCards) { drawn in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(drawn.position.rawValue)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AstroTheme.accent)
                            .textCase(.uppercase)
                        Text(drawn.card.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        if drawn.isReversed {
                            Text("(Ters)")
                                .font(.caption2)
                                .foregroundStyle(AstroTheme.zorlayici)
                        }
                    }
                    Text(drawn.interpretation)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 12))
            }
        }
        .glassCard()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Sıfırla

    private var resetButton: some View {
        Button {
            withAnimation(.spring(duration: 0.4)) {
                isUnlockedByAd = false
                vm.reset()
            }
        } label: {
            Label("Tekrar Çek", systemImage: "arrow.counterclockwise")
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
}
