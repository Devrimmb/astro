import SwiftUI

struct KatinaView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = KatinaViewModel()
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
                    if !canDraw && vm.drawnCard == nil {
                        adGateSection
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
        .navigationTitle("Katina Falı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(vm.drawnCard != nil && !vm.isRevealed)
        .toolbar {
            if vm.drawnCard != nil && !vm.isRevealed {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        backToFan()
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

    // MARK: - Reklam Kapisi

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("\u{1F52E}")
                .font(.system(size: 48))

            VStack(spacing: 8) {
                Text("Katina Falı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Bugünkü ücretsiz hakkını kullandın")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            AdGateView(
                title: "Tekrar Fal Bak",
                description: "Kartını tekrar çekmek için kısa bir reklam izle veya Pro'ya geç."
            ) {
                isUnlockedByAd = true
            }
        }
    }

    // MARK: - Yelpaze

    private var fanView: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 20)

            // Mystik baslik
            VStack(spacing: 12) {
                // Animated crystal ball
                Text("\u{1F52E}")
                    .font(.system(size: 56))
                    .shadow(color: AstroTheme.accent.opacity(0.6), radius: 20)
                    .scaleEffect(1.0 + sin(glowPhase * 2) * 0.05)

                Text("Katina Falı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Zihnini odakla ve bir kart seç")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
                    .opacity(instructionOpacity)
            }

            // Yelpaze kartlari
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
        // Staggered kart dagitimi
        for i in 0..<fanCardCount {
            withAnimation(
                .spring(duration: 0.7, bounce: 0.3)
                .delay(Double(i) * 0.08)
            ) {
                cardsDealt = true
            }
        }

        // Instruction text fade in
        withAnimation(.easeIn(duration: 0.6).delay(0.8)) {
            instructionOpacity = 1.0
        }

        // Continuous glow + float animation
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
            // Kart glow efekti
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.55, blue: 0.2).opacity(0.4),
                            Color(red: 0.6, green: 0.3, blue: 0.1).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 8)
                .scaleEffect(1.1)
                .opacity(0.5 + sin(glowPhase + Double(index) * 0.9) * 0.3)

            // Kart arka plani
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.6, green: 0.38, blue: 0.18),
                            Color(red: 0.4, green: 0.22, blue: 0.08),
                            Color(red: 0.3, green: 0.15, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Inner border shimmer
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.6),
                                    Color(red: 0.7, green: 0.45, blue: 0.2).opacity(0.2),
                                    Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }

            // Kart deseni
            VStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0.45).opacity(0.5))

                Text("\u{2726}")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.8, blue: 0.45),
                                Color(red: 0.7, green: 0.5, blue: 0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0.45).opacity(0.5))
            }
        }
        .frame(width: 72, height: 115)
        .shadow(color: Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.5), radius: 4, x: 1, y: 2)
        // Pozisyon & animasyonlar
        .rotationEffect(
            .degrees(isSelected ? 0 : fanAngle(for: index)),
            anchor: .bottom
        )
        .offset(y: cardsDealt
            ? (isSelected ? -40 : fanYOffset(for: index) + floatOffset)
            : 300 // Baslangic: ekranin altindan gelir
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

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            selectedFanIndex = index
        }

        // Sparkle efekti
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

    private func backToFan() {
        withAnimation(.spring(duration: 0.4)) {
            vm.reset()
            selectedFanIndex = nil
            flipProgress = 0
            showSparkles = false
            revealBurst = false
            cardScale = 1.0
        }
        // Re-deal animation
        cardsDealt = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dealCards()
        }
    }

    private var flipCardView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 30)

            Text(flipProgress < 90 ? "Kartına dokun ve aç" : "")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AstroTheme.textSecondary)
                .animation(.easeInOut(duration: 0.3), value: flipProgress)
                .opacity(flipProgress < 90 ? 1 : 0)

            ZStack {
                // Arkadaki glow efekti
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

                // Sparkle particles
                if showSparkles || revealBurst {
                    SparkleField(burst: revealBurst)
                }

                // Arka yuz (kapali)
                if flipProgress < 90 {
                    cardBackFace
                        .rotation3DEffect(
                            .degrees(flipProgress),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.4
                        )
                }

                // On yuz (acik)
                if flipProgress >= 90, let card = vm.drawnCard {
                    cardFrontFace(card: card)
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

            // Karti degistir butonu
            if flipProgress == 0 {
                Button {
                    backToFan()
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
            // Subtle pulse on appear
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                showSparkles = true
            }
        }
    }

    private var cardBackFace: some View {
        ZStack {
            // Shadow base
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 15)
                .offset(y: 8)

            // Main card
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.7, green: 0.45, blue: 0.15),
                            Color(red: 0.5, green: 0.28, blue: 0.08),
                            Color(red: 0.35, green: 0.18, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    // Ornamental border
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.8, blue: 0.5).opacity(0.7),
                                    Color(red: 0.7, green: 0.45, blue: 0.2).opacity(0.3),
                                    Color(red: 0.95, green: 0.8, blue: 0.5).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .overlay {
                    // Inner decorative border
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.25),
                            lineWidth: 1
                        )
                        .padding(8)
                }

            // Kart icerigi
            VStack(spacing: 16) {
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0.45).opacity(0.6))

                Text("\u{1F52E}")
                    .font(.system(size: 52))
                    .shadow(color: Color(red: 0.8, green: 0.5, blue: 0.2).opacity(0.5), radius: 10)

                Text("Dokun ve Aç")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0.45).opacity(0.6))
                    .tracking(2)

                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0.45).opacity(0.6))
            }
        }
        .frame(width: 190, height: 280)
    }

    private func cardFrontFace(card: KatinaCard) -> some View {
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

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        // 3D flip
        withAnimation(.spring(duration: 0.7, bounce: 0.12)) {
            flipProgress = 180
        }

        // Burst effect at midpoint
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                revealBurst = true
            }

            // Scale pop
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
            appState.gamification.earn(.cardReading)
        }
    }

    // MARK: - Acilmis Kart + Yorum

    private var revealedCardView: some View {
        VStack(spacing: 20) {
            if let card = vm.drawnCard {
                // Kart resmi ve başlığı
                VStack(spacing: 0) {
                    Image(card.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)

                    Text(card.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(AstroTheme.surface)
                }
                .frame(maxWidth: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AstroTheme.cardBorder, lineWidth: 1)
                }
                .shadow(color: AstroTheme.accent.opacity(0.2), radius: 15)
                .transition(.scale(scale: 0.9).combined(with: .opacity))

                // Markdown yorum
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kartın Yorumu")
                        .font(.headline)
                        .foregroundStyle(.white)

                    MarkdownTextView(card.description)
                }
                .glassCard()
                .transition(.move(edge: .bottom).combined(with: .opacity))

                // Paylas
                Button {
                    ShareImageRenderer.shareKatina(card: card)
                    appState.gamification.earn(.shareResult)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Sonucu Paylaş")
                    }
                    .glassButton()
                }
                .transition(.scale.combined(with: .opacity))

                // Tekrar cek
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        isUnlockedByAd = false
                        resetAll()
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
                .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.6, bounce: 0.2), value: vm.isRevealed)
    }
}

// MARK: - Sparkle Particles

private struct SparkleField: View {
    let burst: Bool
    @State private var particles: [SparkleParticle] = (0..<12).map { _ in SparkleParticle() }

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

private struct SparkleParticle: Identifiable {
    let id = UUID()
    let size: CGFloat = .random(in: 6...14)
    let color: Color = [
        Color(red: 0.95, green: 0.8, blue: 0.4),
        Color(red: 0.8, green: 0.6, blue: 0.3),
        Color(red: 0.56, green: 0.44, blue: 1.0),
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
