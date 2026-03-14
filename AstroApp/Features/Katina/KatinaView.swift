import SwiftUI

struct KatinaView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var vm = KatinaViewModel()
    @State private var isUnlockedByAd = false

    // Yelpaze state
    @State private var selectedFanIndex: Int?
    @State private var fanCollapsed = false
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
        fanCollapsed = false
        flipProgress = 0
    }

    // MARK: - Reklam Kapısı

    private var adGateSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            Text("🔮")
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

            Text("🔮")
                .font(.system(size: 48))

            VStack(spacing: 8) {
                Text("Katina Falı")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Zihnini odakla ve bir kart seç")
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)
            }

            // Yelpaze kartları
            ZStack {
                ForEach(0..<fanCardCount, id: \.self) { index in
                    fanCard(at: index)
                }
            }
            .frame(height: 280)
            .padding(.top, 16)
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
                            Color(red: 0.55, green: 0.32, blue: 0.12),
                            Color(red: 0.35, green: 0.18, blue: 0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.7, green: 0.45, blue: 0.2).opacity(0.5), lineWidth: 1)
                }

            VStack(spacing: 8) {
                Text("✦")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.35).opacity(0.6))
            }
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

    private func backToFan() {
        withAnimation(.spring(duration: 0.4)) {
            vm.reset()
            selectedFanIndex = nil
            fanCollapsed = false
            flipProgress = 0
        }
    }

    private var flipCardView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 30)

            Text(flipProgress < 90 ? "Kartına dokun ve aç" : "")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .animation(.none, value: flipProgress)

            ZStack {
                // Arka yüz (kapalı) — flipProgress < 90 iken görünür
                if flipProgress < 90 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.85, green: 0.55, blue: 0.2).opacity(0.6),
                                        Color(red: 0.6, green: 0.3, blue: 0.1).opacity(0.3)
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
                            Text("🔮")
                                .font(.system(size: 48))
                                .opacity(0.5)
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

                // Ön yüz (açık) — flipProgress >= 90 iken görünür
                if flipProgress >= 90, let card = vm.drawnCard {
                    VStack(spacing: 12) {
                        Text("🔮")
                            .font(.system(size: 48))

                        Text(card.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 180, height: 260)
                    .background(AstroTheme.surface, in: .rect(cornerRadius: 20))
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

            // Kartı değiştir butonu (henüz açılmamışsa)
            if flipProgress == 0 {
                Button {
                    backToFan()
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
            if let card = vm.drawnCard {
                // Kart başlığı
                VStack(spacing: 12) {
                    Text("🔮")
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kartın Yorumu")
                        .font(.headline)
                        .foregroundStyle(.white)

                    MarkdownTextView(card.description)
                }
                .glassCard()
                .transition(.move(edge: .bottom).combined(with: .opacity))

                // Paylaş
                Button {
                    ShareImageRenderer.shareKatina(card: card)
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
            }
        }
    }
}
