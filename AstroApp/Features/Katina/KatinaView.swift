import SwiftUI

struct KatinaView: View {
    @State private var deck: [KatinaCard] = JSONLoader.load("katina_cards")

    var body: some View {
        DeckReadingFlow(
            config: .init(
                title: "Katina Falı",
                glyph: "♡\u{FE0E}",
                adDescription: "Kartını tekrar çekmek için kısa bir reklam izle.",
                subtitle: "Kalbindeki soruyu tut, desteyi masaya ser",
                quotaKey: "katina_last_free_reading_date",
                style: .katina
            ),
            deck: deck,
            cardName: { $0.name },
            front: { card, size in
                DeckPortraitFront(imageName: card.imageName, name: card.name, size: size,
                                  tint: DeckStyle.katina.tint)
            },
            interpretation: { $0.description },
            share: { ShareImageRenderer.shareKatina(card: $0) }
        )
        .navigationTitle("Katina Falı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
