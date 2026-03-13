import Foundation

struct TarotCard: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let arcana: Arcana
    let image: String
    let upright: String
    let reversed: String

    enum Arcana: String, Codable, Sendable {
        case major = "major"
        case minor = "minor"
    }
}

enum TarotSpreadPosition: String, Sendable {
    case past = "Geçmiş"
    case present = "Şimdi"
    case future = "Gelecek"
}

struct DrawnCard: Identifiable, Sendable {
    let id: UUID
    let card: TarotCard
    let position: TarotSpreadPosition
    let isReversed: Bool
    var isRevealed: Bool

    init(card: TarotCard, position: TarotSpreadPosition, isReversed: Bool) {
        self.id = UUID()
        self.card = card
        self.position = position
        self.isReversed = isReversed
        self.isRevealed = false
    }

    var interpretation: String {
        isReversed ? card.reversed : card.upright
    }
}
