import SwiftUI

@Observable
class TarotViewModel {
    var drawnCards: [DrawnCard] = []
    var hasDrawn = false
    private let deck: [TarotCard]

    private static let lastFreeReadingKey = "tarot_last_free_reading_date"

    /// Bugün ücretsiz hak kullanıldı mı?
    var hasFreeReadingToday: Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastFreeReadingKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }

    /// Günlük hakkı kullan
    private func consumeFreeReading() {
        UserDefaults.standard.set(Date(), forKey: Self.lastFreeReadingKey)
    }

    var allRevealed: Bool {
        drawnCards.allSatisfy(\.isRevealed)
    }

    init() {
        deck = JSONLoader.load("tarot_cards")
    }

    func drawCards() {
        let shuffled = deck.shuffled()
        let positions: [TarotSpreadPosition] = [.past, .present, .future]

        drawnCards = (0..<3).map { i in
            DrawnCard(
                card: shuffled[i],
                position: positions[i],
                isReversed: Bool.random()
            )
        }
        hasDrawn = true
        consumeFreeReading()
    }

    func revealCard(_ card: DrawnCard) {
        guard let index = drawnCards.firstIndex(where: { $0.id == card.id }) else { return }
        drawnCards[index].isRevealed = true
    }

    func reset() {
        drawnCards = []
        hasDrawn = false
    }
}
