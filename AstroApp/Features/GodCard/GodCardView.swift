import SwiftUI

struct GodCardView: View {
    @State private var deck: [GodCard] = JSONLoader.load("god_cards")

    var body: some View {
        DeckReadingFlow(
            config: .init(
                title: "Tanrı Kartları",
                glyph: "⚡\u{FE0E}",
                adDescription: "Kartını tekrar çekmek için kısa bir reklam izle.",
                subtitle: "Sorunu tut, tanrıların mesajını çağır",
                readingTitle: "Tanrının Mesajı",
                quotaKey: "god_last_free_reading_date",
                style: .god
            ),
            deck: deck,
            cardName: { $0.name },
            front: { card, size in
                DeckSquareFront(imageName: card.imageName, name: card.name, size: size,
                                tint: DeckStyle.god.tint)
            },
            interpretation: { $0.description },
            share: { ShareImageRenderer.shareGodCard(card: $0) }
        )
        .navigationTitle("Tanrı Kartları")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
