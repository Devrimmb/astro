import SwiftUI

@Observable
class KatinaViewModel {
    var drawnCard: KatinaCard?
    var isRevealed = false

    private let deck: [KatinaCard]

    private static let lastFreeReadingKey = "katina_last_free_reading_date"

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
        deck = JSONLoader.load("katina_cards")
    }

    func drawCard() {
        guard let card = deck.randomElement() else { return }
        drawnCard = card
        consumeFreeReading()
    }

    func revealCard() {
        isRevealed = true
    }

    func reset() {
        drawnCard = nil
        isRevealed = false
    }
}
