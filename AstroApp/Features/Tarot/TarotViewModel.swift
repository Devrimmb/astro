import SwiftUI

@Observable
class TarotViewModel {
    var selectedCategory: TarotCategory?
    var drawnCard: TarotCard?
    var isRevealed = false

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

    /// Seçili kategorideki yorum metni
    var interpretation: String? {
        guard let card = drawnCard, let category = selectedCategory else { return nil }
        return card.descriptions.text(for: category)
    }

    init() {
        deck = JSONLoader.load("tarot_cards")
    }

    func selectCategory(_ category: TarotCategory) {
        selectedCategory = category
    }

    func drawCard() {
        let candidates = deck.filter { $0.id != drawnCard?.id }
        guard let card = candidates.randomElement() else { return }
        drawnCard = card
    }

    func revealCard() {
        isRevealed = true
        consumeFreeReading()
    }

    func reset() {
        selectedCategory = nil
        drawnCard = nil
        isRevealed = false
    }

}
