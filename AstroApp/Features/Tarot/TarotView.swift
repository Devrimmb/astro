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
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 24) {
                    if !canDraw && vm.selectedCategory == nil {
                        adGateSection
                    } else if vm.selectedCategory == nil {
                        categorySelectionView
                    } else if vm.drawnCard == nil {
                        drawCardView
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
        .navigationTitle("Tarot")
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

    // MARK: - Kategori Seçimi

    private var categorySelectionView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            Text("✦")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.accent)

            VStack(spacing: 8) {
                Text("Tarot")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bir kategori seç ve kartını çek")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(TarotCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            vm.selectCategory(category)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundStyle(AstroTheme.accent)
                                .frame(width: 32)

                            Text(category.localizedName)
                                .font(.headline)
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textTertiary)
                        }
                        .padding(16)
                        .background(AstroTheme.surface, in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AstroTheme.cardBorder, lineWidth: 1)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Kart Çek

    private var drawCardView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 40)

            if let category = vm.selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                    Text(category.localizedName)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AstroTheme.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AstroTheme.accent.opacity(0.12), in: .capsule)
            }

            Text("✦")
                .font(.system(size: 56))
                .foregroundStyle(AstroTheme.accent)

            VStack(spacing: 8) {
                Text("Kartını Çek")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Zihnini odakla ve kartına dokun")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            Button {
                withAnimation(.spring(duration: 0.5)) {
                    vm.drawCard()
                }
            } label: {
                Text("Kartı Çek")
                    .glassButton()
            }
            .padding(.top, 12)

            backButton
        }
    }

    // MARK: - Kart Arka Yüz (Kapalı)

    private var cardBackView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 30)

            if let category = vm.selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                    Text(category.localizedName)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AstroTheme.accent)
            }

            Text("Kartına dokun ve aç")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)

            // Kapalı kart
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AstroTheme.accent.opacity(0.6), AstroTheme.accentSecondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AstroTheme.cardBorder, lineWidth: 1)
                    }

                VStack(spacing: 12) {
                    Text("✦")
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

    // MARK: - Açılmış Kart + Yorum

    private var revealedCardView: some View {
        VStack(spacing: 20) {
            if let card = vm.drawnCard, let category = vm.selectedCategory {
                // Kategori etiketi
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                    Text(category.localizedName)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AstroTheme.accent)
                .padding(.top, 8)

                // Kart görseli
                VStack(spacing: 12) {
                    Text(card.image)
                        .font(.system(size: 48))

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
                if let interpretation = vm.interpretation {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kartın Yorumu")
                            .font(.headline)
                            .foregroundStyle(.white)

                        MarkdownTextView(interpretation)
                    }
                    .glassCard()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Paylaş
                Button {
                    ShareImageRenderer.shareTarot(card: card, category: category)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Sonucu Paylaş")
                    }
                    .glassButton()
                }

                // Tekrar kart çek → kategori seçimine dön
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        isUnlockedByAd = false
                        vm.reset()
                    }
                } label: {
                    Label("Tekrar Kart Çek", systemImage: "arrow.counterclockwise")
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

    // MARK: - Ortak Butonlar

    private var backButton: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                vm.reset()
            }
        } label: {
            Label("Geri", systemImage: "chevron.left")
                .font(.caption.weight(.medium))
                .foregroundStyle(AstroTheme.textSecondary)
        }
    }
}
