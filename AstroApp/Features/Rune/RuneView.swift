import SwiftUI

struct RuneView: View {
    @State private var deck: [RuneCard] = JSONLoader.load("rune_cards")

    var body: some View {
        DeckReadingFlow(
            config: .init(
                title: "Rün Falı",
                glyph: "ᚱ",
                adDescription: "Rünü tekrar çekmek için kısa bir reklam izle.",
                subtitle: "Sorunu düşün, rünleri masaya ser",
                readingTitle: "Rünün Yorumu",
                quotaKey: "rune_last_free_reading_date",
                style: .rune
            ),
            deck: deck,
            cardName: { $0.name },
            front: { card, size in
                DeckSymbolFront(symbol: card.symbol, name: card.name, size: size,
                                tint: DeckStyle.rune.tint,
                                colors: DeckStyle.rune.backColors)
            },
            interpretation: { $0.description },
            share: { ShareImageRenderer.shareRune(card: $0) }
        )
        .navigationTitle("Rün Falı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
