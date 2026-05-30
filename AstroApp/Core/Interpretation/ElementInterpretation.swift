import Foundation

struct ElementEntry: Codable, Sendable, Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let description: String
    let less: String
    let more: String
    let balance: String
}

/// Element yorum veritabanı — eksik / fazla / dengeli durumlarına göre yorum.
enum ElementInterpretation {
    private static let entries: [ElementEntry] = {
        let data: [ElementEntry] = JSONLoader.load("element_interpretations")
        return data
    }()

    /// Element key'ine göre yorum getir (Fire, Water, Earth, Air)
    static func entry(for element: ZodiacSign.Element) -> ElementEntry? {
        let key = elementKey(element)
        return entries.first { $0.key == key }
    }

    /// Element durumunu belirle (ağırlıklı toplam puana göre)
    static func status(score: Double, totalScore: Double) -> ElementStatus {
        let average = totalScore / 4.0
        if score <= average * 0.4 {
            return .less
        } else if score >= average * 1.6 {
            return .more
        }
        return .balance
    }

    /// Element durumuna göre yorum metnini getir
    static func interpretation(for element: ZodiacSign.Element, score: Double, totalScore: Double) -> String? {
        guard let entry = entry(for: element) else { return nil }
        let status = status(score: score, totalScore: totalScore)
        switch status {
        case .less: return entry.less
        case .more: return entry.more
        case .balance: return entry.balance
        }
    }

    enum ElementStatus {
        case less, more, balance

        var displayName: String {
            switch self {
            case .less: "Eksik"
            case .more: "Baskın"
            case .balance: "Dengeli"
            }
        }

        var icon: String {
            switch self {
            case .less: "arrow.down.circle.fill"
            case .more: "arrow.up.circle.fill"
            case .balance: "checkmark.circle.fill"
            }
        }
    }

    private static func elementKey(_ element: ZodiacSign.Element) -> String {
        switch element {
        case .fire: "Fire"
        case .earth: "Earth"
        case .air: "Air"
        case .water: "Water"
        }
    }
}
