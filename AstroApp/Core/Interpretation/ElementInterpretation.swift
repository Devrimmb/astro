import Foundation

struct ElementEntry: Codable, Sendable, Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let description: String
    let less: String
    let limited: String
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

    /// Element durumunu puana göre belirle
    /// EKSİK: 0.00–1.50 | SINIRLI: 1.75–3.99 | DENGELİ: 4.00–7.99 | BASKIN: 8.00+
    static func status(score: Double, totalScore: Double) -> ElementStatus {
        switch score {
        case ..<1.51:   return .less
        case 1.51..<4.0: return .limited
        case 4.0..<8.0:  return .balance
        default:         return .more
        }
    }

    /// Element durumuna göre yorum metnini getir
    static func interpretation(for element: ZodiacSign.Element, score: Double, totalScore: Double) -> String? {
        guard let entry = entry(for: element) else { return nil }
        let status = status(score: score, totalScore: totalScore)
        switch status {
        case .less:    return entry.less
        case .limited: return entry.limited
        case .more:    return entry.more
        case .balance: return entry.balance
        }
    }

    enum ElementStatus {
        case less, limited, balance, more

        var displayName: String {
            switch self {
            case .less:    "Eksik"
            case .limited: "Sınırlı"
            case .balance: "Dengeli"
            case .more:    "Baskın"
            }
        }

        var icon: String {
            switch self {
            case .less:    "arrow.down.circle.fill"
            case .limited: "minus.circle.fill"
            case .balance: "checkmark.circle.fill"
            case .more:    "arrow.up.circle.fill"
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
