import SwiftUI

@Observable
class RuneViewModel {
    var drawnCard: RuneCard?
    var isRevealed = false

    private let deck: [RuneCard]

    private static let lastFreeReadingKey = "rune_last_free_reading_date"

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

    init() {
        deck = JSONLoader.load("rune_cards")
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
        drawnCard = nil
        isRevealed = false
    }
}
