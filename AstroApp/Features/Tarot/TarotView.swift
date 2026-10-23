import SwiftUI

struct TarotView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = TarotViewModel()
    @State private var isUnlockedByAd = false
    /// Her yeni çekimde çark sıfırdan kurulsun diye kimlik sayacı
    @State private var wheelRun = 0

    private var canDraw: Bool {
        entitlements.hasNatalChart || vm.hasFreeReadingToday || isUnlockedByAd
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            if !canDraw && vm.selectedCategory == nil {
                ScrollView {
                    adGateSection
                        .padding()
                        .padding(.bottom, 40)
                }
            } else if vm.selectedCategory == nil {
                ScrollView {
                    categorySelectionView
                        .padding()
                        .padding(.bottom, 40)
                }
            } else {
                wheelSection
            }
        }
        .navigationTitle("Tarot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(vm.selectedCategory != nil && !vm.isRevealed)
        .toolbar {
            if vm.selectedCategory != nil && !vm.isRevealed {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(duration: 0.4)) { vm.reset() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .onDisappear {
            resetAll()
        }
    }

    private func resetAll() {
        vm.reset()
        isUnlockedByAd = false
        wheelRun += 1
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
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Fal Bak",
                description: "Kartları tekrar çekmek için kısa bir reklam izle."
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
                    .font(.largeTitle)
                    .fontDesign(.serif)
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

    // MARK: - Deste çarkı (karıştır → ser → seç → çevir → yorum)

    private var wheelSection: some View {
        DeckWheelView(
            deck: vm.deck,
            style: .tarot,
            subtitle: "Zihnini sorunda tut, desteyi masaya ser",
            cardName: { $0.name },
            front: { card, size in tarotFront(card, size: size) },
            panel: { picks, _ in readingPanel(picks) },
            onReveal: { picks in
                guard let first = picks.first else { return }
                vm.drawnCard = first.card
                vm.revealCard()
            }
        )
        .id(wheelRun)
        .overlay(alignment: .top) {
            if let category = vm.selectedCategory {
                categoryChip(category)
                    .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }

    private func categoryChip(_ category: TarotCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
            Text(category.localizedName)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AstroTheme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AstroTheme.accent.opacity(0.12), in: .capsule)
        .overlay { Capsule().stroke(AstroTheme.accent.opacity(0.25), lineWidth: 1) }
    }

    /// Seçilen kartın ön yüzü: 400×700 görsel + altta ad şeridi
    private func tarotFront(_ card: TarotCard, size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
        return ZStack(alignment: .bottom) {
            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            LinearGradient(colors: [.clear, AstroTheme.background.opacity(0.92)],
                           startPoint: .init(x: 0.5, y: 0.55), endPoint: .bottom)

            Text(card.name)
                .font(.system(size: size.width * 0.105, weight: .semibold, design: .serif))
                .foregroundStyle(AstroTheme.gold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, size.width * 0.08)
                .padding(.bottom, size.height * 0.05)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(AstroTheme.gold.opacity(0.85), lineWidth: max(1, size.width * 0.014)))
        .shadow(color: AstroTheme.accent.opacity(0.35), radius: 18, y: 8)
    }

    // MARK: - Okuma paneli

    @ViewBuilder
    private func readingPanel(_ picks: [DeckPick<TarotCard>]) -> some View {
        if let pick = picks.first, let category = vm.selectedCategory {
            let card = pick.card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.name)
                        .font(.title2)
                        .fontDesign(.serif)
                        .foregroundStyle(AstroTheme.gold)
                    Spacer()
                    Pill(text: category.rawValue, color: AstroTheme.accent, icon: category.icon)
                }

                Rectangle()
                    .fill(AstroTheme.accent.opacity(0.24))
                    .frame(height: 1)

                Text("Kartın Yorumu")
                    .font(.headline)
                    .foregroundStyle(.white)

                MarkdownTextView(card.descriptions.text(for: category))

                HStack(spacing: 12) {
                    Button {
                        ShareImageRenderer.shareTarot(card: card, category: category)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Paylaş")
                        }
                        .glassButton()
                    }

                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            isUnlockedByAd = false
                            resetAll()
                        }
                    } label: {
                        Label("Tekrar Kart Çek", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(AstroTheme.surface, in: .capsule)
                            .overlay { Capsule().stroke(AstroTheme.cardBorder, lineWidth: 1) }
                    }
                }
                .padding(.top, 6)
            }
        }
    }
}
