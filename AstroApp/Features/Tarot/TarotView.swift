import SwiftUI

struct TarotView: View {
    @State private var deck: [TarotCard] = JSONLoader.load("tarot_cards")
    @State private var selectedCategory: TarotCategory?

    var body: some View {
        ZStack {
            if let category = selectedCategory {
                readingFlow(category)
                    .transition(.opacity)
            } else {
                ZStack {
                    SubtleStarsBackground()
                    ScrollView {
                        categorySelectionView
                            .padding()
                            .padding(.bottom, 40)
                    }
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Tarot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(selectedCategory != nil)
        .toolbar {
            if selectedCategory != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(duration: 0.4)) { selectedCategory = nil }
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
        .onDisappear { selectedCategory = nil }
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
                            selectedCategory = category
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

    // MARK: - Ortak akış (reklam kapısı → çark → yorum)

    private func readingFlow(_ category: TarotCategory) -> some View {
        DeckReadingFlow(
            config: .init(
                title: "Tarot",
                glyph: "✦",
                adDescription: "Kartları tekrar çekmek için kısa bir reklam izle.",
                quotaKey: "tarot_last_free_reading_date",
                style: .tarot
            ),
            deck: deck,
            cardName: { $0.name },
            front: { card, size in
                DeckPortraitFront(imageName: card.imageName, name: card.name, size: size)
            },
            interpretation: { $0.descriptions.text(for: category) },
            share: { ShareImageRenderer.shareTarot(card: $0, category: category) },
            badge: Pill(text: category.rawValue, color: AstroTheme.accent, icon: category.icon),
            onAgain: { selectedCategory = nil }
        )
        .id(category)
    }
}
