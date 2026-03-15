import SwiftUI

struct TarotView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = TarotViewModel()
    @State private var isUnlockedByAd = false

    // Yelpaze state
    @State private var selectedFanIndex: Int?
    @State private var flipProgress: Double = 0

    private let fanCardCount = 7

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
                    } else if vm.drawnCard == nil && selectedFanIndex == nil {
                        fanView
                    } else if vm.drawnCard != nil && !vm.isRevealed {
                        flipCardView
                    } else if vm.isRevealed {
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
        .navigationBarBackButtonHidden(vm.selectedCategory != nil && !vm.isRevealed)
        .toolbar {
            if vm.selectedCategory != nil && !vm.isRevealed {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        backAction()
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

    /// Geri butonunun davranışı duruma göre değişir
    private func backAction() {
        withAnimation(.spring(duration: 0.4)) {
            if vm.drawnCard != nil {
                // Flip aşamasında → yelpaze'ye dön
                backToFan()
            } else {
                // Yelpaze aşamasında → kategori seçimine dön
                vm.reset()
                selectedFanIndex = nil
                flipProgress = 0
            }
        }
    }

    private func resetAll() {
        vm.reset()
        isUnlockedByAd = false
        selectedFanIndex = nil
        flipProgress = 0
    }

    private func backToFan() {
        vm.drawnCard = nil
        vm.isRevealed = false
        selectedFanIndex = nil
        flipProgress = 0
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

    // MARK: - Yelpaze

    private var fanView: some View {
        VStack(spacing: 28) {
            Spacer().frame(height: 20)

            // Kategori etiketi
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
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.accent)

            VStack(spacing: 8) {
                Text("Kartını Seç")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Zihnini odakla ve bir kart seç")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            ZStack {
                ForEach(0..<fanCardCount, id: \.self) { index in
                    fanCard(at: index)
                }
            }
            .frame(height: 280)
            .padding(.top, 8)
        }
    }

    private func fanCard(at index: Int) -> some View {
        let isSelected = selectedFanIndex == index
        let hasSelection = selectedFanIndex != nil

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.15, blue: 0.45),
                            Color(red: 0.15, green: 0.08, blue: 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.45, green: 0.3, blue: 0.7).opacity(0.5), lineWidth: 1)
                }

            Text("✦")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.5))
        }
        .frame(width: 70, height: 110)
        .shadow(color: .black.opacity(0.4), radius: 4, x: 1, y: 2)
        .rotationEffect(
            .degrees(isSelected ? 0 : fanAngle(for: index)),
            anchor: .bottom
        )
        .offset(y: isSelected ? -30 : fanYOffset(for: index))
        .scaleEffect(isSelected ? 1.3 : (hasSelection ? 0.7 : 1.0))
        .opacity(hasSelection && !isSelected ? 0 : 1)
        .zIndex(isSelected ? 10 : Double(index))
        .onTapGesture {
            guard selectedFanIndex == nil else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                selectedFanIndex = index
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                vm.drawCard()
            }
        }
    }

    private func fanAngle(for index: Int) -> Double {
        let mid = Double(fanCardCount - 1) / 2.0
        return (Double(index) - mid) * 12
    }

    private func fanYOffset(for index: Int) -> Double {
        let mid = Double(fanCardCount - 1) / 2.0
        let distance = abs(Double(index) - mid)
        return distance * distance * 4
    }

    // MARK: - 3D Flip Kart

    private var flipCardView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 30)

            // Kategori etiketi
            if let category = vm.selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                    Text(category.localizedName)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AstroTheme.accent)
            }

            Text(flipProgress < 90 ? "Kartına dokun ve aç" : "")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .animation(.none, value: flipProgress)

            ZStack {
                // Arka yüz
                if flipProgress < 90 {
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
                    .rotation3DEffect(
                        .degrees(flipProgress),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                }

                // Ön yüz
                if flipProgress >= 90, let card = vm.drawnCard {
                    VStack(spacing: 0) {
                        Image(card.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        Text(card.name)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(AstroTheme.surface)
                    }
                    .frame(width: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AstroTheme.cardBorder, lineWidth: 1)
                    }
                    .rotation3DEffect(
                        .degrees(flipProgress - 180),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                }
            }
            .onTapGesture {
                guard flipProgress == 0 else { return }
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    flipProgress = 180
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    vm.revealCard()
                }
            }

            if flipProgress == 0 {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        backToFan()
                    }
                } label: {
                    Label("Kartı Değiştir", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                .padding(.top, 8)
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
                VStack(spacing: 0) {
                    Image(card.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    Text(card.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(AstroTheme.surface)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AstroTheme.cardBorder, lineWidth: 1)
                }
                .shadow(color: AstroTheme.accent.opacity(0.2), radius: 15)

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
                        resetAll()
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
}
