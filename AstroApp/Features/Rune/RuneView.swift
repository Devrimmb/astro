import SwiftUI

struct RuneView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = RuneViewModel()
    @State private var isUnlockedByAd = false

    /// Kullanıcı rune çekebilir mi?
    private var canDraw: Bool {
        entitlements.hasNatalChart || vm.hasFreeReadingToday || isUnlockedByAd
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 24) {
                    if !canDraw && vm.drawnCard == nil {
                        adGateSection
                    } else if vm.drawnCard == nil {
                        introView
                    } else if !vm.isRevealed {
                        cardBackView
                    } else {
                        revealedCardView
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Rune Falı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onDisappear {
            vm.reset()
            isUnlockedByAd = false
        }
    }

    // MARK: - Reklam Kapısı

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("ᚱ")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Rune Falı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Fal Bak",
                description: "Runeni tekrar çekmek için kısa bir reklam izle veya Pro'ya geç."
            ) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: - Giriş

    private var introView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            Text("ᚱ")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Rune Falı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Kadim Viking runelerinden rehberlik al")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            Button {
                withAnimation(.spring(duration: 0.5)) {
                    vm.drawCard()
                }
            } label: {
                Text("Runeni Çek")
                    .glassButton()
            }
            .padding(.top, 12)
        }
    }

    // MARK: - Kart Arka Yüz (Kapalı)

    private var cardBackView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            Text("Runene dokun ve aç")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.6),
                                Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AstroTheme.cardBorder, lineWidth: 1)
                    }

                VStack(spacing: 12) {
                    Text("ᚱ")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Dokun ve Aç")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 180, height: 260)
            .onTapGesture {
                withAnimation(.spring(duration: 0.6)) {
                    vm.revealCard()
                }
            }
        }
    }

    // MARK: - Açılmış Rune + Yorum

    private var revealedCardView: some View {
        VStack(spacing: 20) {
            if let card = vm.drawnCard {
                // Rune görseli
                VStack(spacing: 12) {
                    Text(card.symbol)
                        .font(.system(size: 56))

                    Text(card.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(AstroTheme.surface, in: .rect(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AstroTheme.cardBorder, lineWidth: 1)
                }

                // Markdown yorum
                VStack(alignment: .leading, spacing: 12) {
                    Text("Runenin Yorumu")
                        .font(.headline)
                        .foregroundStyle(.white)

                    MarkdownTextView(card.description)
                }
                .glassCard()
                .transition(.move(edge: .bottom).combined(with: .opacity))

                // Paylaş
                Button {
                    ShareImageRenderer.shareRune(card: card)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Sonucu Paylaş")
                    }
                    .glassButton()
                }

                // Tekrar çek
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
    }
}
