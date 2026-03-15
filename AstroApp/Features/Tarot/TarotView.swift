import SwiftUI

struct TarotView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = TarotViewModel()
    @State private var isUnlockedByAd = false

    // Fan state
    @State private var selectedFanIndex: Int?
    @State private var flipProgress: Double = 0

    // Animation states
    @State private var cardsDealt = false
    @State private var glowPhase: Double = 0
    @State private var floatPhase: Double = 0
    @State private var showSparkles = false
    @State private var revealBurst = false
    @State private var cardScale: CGFloat = 1.0
    @State private var instructionOpacity: Double = 0

    private let fanCardCount = 7

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

    private func backAction() {
        withAnimation(.spring(duration: 0.4)) {
            if vm.drawnCard != nil {
                backToFan()
            } else {
                vm.reset()
                selectedFanIndex = nil
                flipProgress = 0
                cardsDealt = false
                glowPhase = 0
                floatPhase = 0
                instructionOpacity = 0
            }
        }
    }

    private func resetAll() {
        vm.reset()
        isUnlockedByAd = false
        selectedFanIndex = nil
        flipProgress = 0
        cardsDealt = false
        glowPhase = 0
        floatPhase = 0
        showSparkles = false
        revealBurst = false
        cardScale = 1.0
        instructionOpacity = 0
    }

    private func backToFan() {
        vm.drawnCard = nil
        vm.isRevealed = false
        selectedFanIndex = nil
        flipProgress = 0
        showSparkles = false
        revealBurst = false
        cardScale = 1.0
        // Re-deal
        cardsDealt = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dealCards()
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

    // MARK: - Yelpaze

    private var fanView: some View {
        VStack(spacing: 24) {
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

            // Animated star
            VStack(spacing: 12) {
                Text("✦")
                    .font(.system(size: 56))
                    .foregroundStyle(AstroTheme.accent)
                    .shadow(color: AstroTheme.accent.opacity(0.6), radius: 20)
                    .scaleEffect(1.0 + sin(glowPhase * 2) * 0.05)

                Text("Kartını Seç")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Zihnini odakla ve bir kart seç")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .opacity(instructionOpacity)
            }

            // Yelpaze
            ZStack {
                // Glow base
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                AstroTheme.accent.opacity(0.15 + sin(glowPhase) * 0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 200)
                    .offset(y: 40)
                    .blur(radius: 20)

                ForEach(0..<fanCardCount, id: \.self) { index in
                    fanCard(at: index)
                }
            }
            .frame(height: 300)
            .padding(.top, 8)
        }
        .onAppear {
            dealCards()
        }
    }

    private func dealCards() {
        for i in 0..<fanCardCount {
            withAnimation(
                .spring(duration: 0.7, bounce: 0.3)
                .delay(Double(i) * 0.08)
            ) {
                cardsDealt = true
            }
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.8)) {
            instructionOpacity = 1.0
        }

        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            glowPhase = .pi * 2
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            floatPhase = 1.0
        }
    }

    private func fanCard(at index: Int) -> some View {
        let isSelected = selectedFanIndex == index
        let hasSelection = selectedFanIndex != nil
        let floatOffset = sin(floatPhase * .pi + Double(index) * 0.3) * 3

        return ZStack {
            // Glow efekti
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AstroTheme.accent.opacity(0.4),
                            AstroTheme.accentSecondary.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 8)
                .scaleEffect(1.1)
                .opacity(0.5 + sin(glowPhase + Double(index) * 0.9) * 0.3)

            // Kart
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.18, blue: 0.55),
                            Color(red: 0.18, green: 0.1, blue: 0.38),
                            Color(red: 0.12, green: 0.06, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AstroTheme.accent.opacity(0.6),
                                    AstroTheme.accent.opacity(0.2),
                                    AstroTheme.accent.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }

            // Desen
            VStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(AstroTheme.accent.opacity(0.5))

                Text("✦")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AstroTheme.accent.opacity(0.8),
                                AstroTheme.accentSecondary.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(AstroTheme.accent.opacity(0.5))
            }
        }
        .frame(width: 72, height: 115)
        .shadow(color: AstroTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.5), radius: 4, x: 1, y: 2)
        .rotationEffect(
            .degrees(isSelected ? 0 : fanAngle(for: index)),
            anchor: .bottom
        )
        .offset(y: cardsDealt
            ? (isSelected ? -40 : fanYOffset(for: index) + floatOffset)
            : 300
        )
        .scaleEffect(isSelected ? 1.4 : (hasSelection ? 0.6 : 1.0))
        .opacity(cardsDealt ? (hasSelection && !isSelected ? 0 : 1) : 0)
        .blur(radius: hasSelection && !isSelected ? 2 : 0)
        .zIndex(isSelected ? 10 : Double(index))
        .animation(
            .spring(duration: 0.6, bounce: 0.25),
            value: selectedFanIndex
        )
        .onTapGesture {
            selectCard(at: index)
        }
    }

    private func selectCard(at index: Int) {
        guard selectedFanIndex == nil else { return }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            selectedFanIndex = index
        }

        withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
            showSparkles = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            vm.drawCard()
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AstroTheme.textSecondary)
                .animation(.easeInOut(duration: 0.3), value: flipProgress)
                .opacity(flipProgress < 90 ? 1 : 0)

            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AstroTheme.accent.opacity(revealBurst ? 0.5 : 0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: revealBurst ? 250 : 100
                        )
                    )
                    .frame(width: 400, height: 400)
                    .scaleEffect(revealBurst ? 1.5 : 1.0)

                // Sparkles
                if showSparkles || revealBurst {
                    TarotSparkleField(burst: revealBurst)
                }

                // Arka yüz
                if flipProgress < 90 {
                    tarotCardBackFace
                        .rotation3DEffect(
                            .degrees(flipProgress),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                }

                // Ön yüz
                if flipProgress >= 90, let card = vm.drawnCard {
                    tarotCardFrontFace(card: card)
                        .rotation3DEffect(
                            .degrees(flipProgress - 180),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                        .scaleEffect(cardScale)
                }
            }
            .onTapGesture {
                flipCard()
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
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                showSparkles = true
            }
        }
    }

    private var tarotCardBackFace: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 15)
                .offset(y: 8)

            // Main card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.2, blue: 0.6),
                            Color(red: 0.22, green: 0.12, blue: 0.45),
                            Color(red: 0.15, green: 0.08, blue: 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    AstroTheme.accent.opacity(0.7),
                                    AstroTheme.accentSecondary.opacity(0.3),
                                    AstroTheme.accent.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            AstroTheme.accent.opacity(0.2),
                            lineWidth: 1
                        )
                        .padding(8)
                }

            VStack(spacing: 16) {
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(AstroTheme.accent.opacity(0.6))

                Text("✦")
                    .font(.system(size: 52))
                    .foregroundStyle(AstroTheme.accent.opacity(0.4))
                    .shadow(color: AstroTheme.accent.opacity(0.5), radius: 10)

                Text("Dokun ve Aç")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AstroTheme.accent.opacity(0.5))
                    .tracking(2)

                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(AstroTheme.accent.opacity(0.6))
            }
        }
        .frame(width: 190, height: 280)
    }

    private func tarotCardFrontFace(card: TarotCard) -> some View {
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
        .frame(width: 190)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AstroTheme.accent.opacity(0.5),
                            AstroTheme.accent.opacity(0.1),
                            AstroTheme.accent.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        }
        .shadow(color: AstroTheme.accent.opacity(0.3), radius: 20)
    }

    private func flipCard() {
        guard flipProgress == 0 else { return }

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.spring(duration: 0.7, bounce: 0.12)) {
            flipProgress = 180
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                revealBurst = true
            }

            withAnimation(.spring(duration: 0.4, bounce: 0.3).delay(0.1)) {
                cardScale = 1.08
            }
            withAnimation(.spring(duration: 0.3).delay(0.4)) {
                cardScale = 1.0
            }

            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            vm.revealCard()
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
                .transition(.scale(scale: 0.9).combined(with: .opacity))

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
                .transition(.scale.combined(with: .opacity))

                // Tekrar kart çek
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
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.2), value: vm.isRevealed)
    }
}

// MARK: - Tarot Sparkle Particles

private struct TarotSparkleField: View {
    let burst: Bool
    @State private var particles: [TarotSparkleParticle] = (0..<12).map { _ in TarotSparkleParticle() }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size))
                    .foregroundStyle(particle.color)
                    .offset(
                        x: burst ? particle.burstX : particle.x,
                        y: burst ? particle.burstY : particle.y
                    )
                    .opacity(particle.opacity)
                    .scaleEffect(burst ? particle.burstScale : particle.scale)
            }
        }
        .animation(.easeOut(duration: 0.8), value: burst)
        .onAppear {
            animateParticles()
        }
    }

    private func animateParticles() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            for i in particles.indices {
                particles[i].opacity = Double.random(in: 0.3...0.8)
                particles[i].scale = CGFloat.random(in: 0.6...1.2)
            }
        }
    }
}

private struct TarotSparkleParticle: Identifiable {
    let id = UUID()
    let size: CGFloat = .random(in: 6...14)
    let color: Color = [
        Color(red: 0.56, green: 0.44, blue: 1.0),
        Color(red: 0.35, green: 0.78, blue: 0.98),
        Color(red: 0.7, green: 0.55, blue: 1.0),
        Color.white
    ].randomElement()!
    let x: CGFloat = .random(in: -80...80)
    let y: CGFloat = .random(in: -120...120)
    let burstX: CGFloat = .random(in: -160...160)
    let burstY: CGFloat = .random(in: -200...200)
    let burstScale: CGFloat = .random(in: 0.3...1.5)
    var opacity: Double = .random(in: 0.2...0.7)
    var scale: CGFloat = 1.0
}
