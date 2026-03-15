import SwiftUI

struct TarotCard: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let arcana: Arcana
    let image: String
    let descriptions: Descriptions

    var imageName: String { "tarot_\(id)" }

    enum Arcana: String, Codable, Sendable {
        case major
        case minor
    }

    struct Descriptions: Codable, Sendable {
        let love: String
        let career: String
        let general: String
        let yesno: String

        func text(for category: TarotCategory) -> String {
            switch category {
            case .love: love
            case .career: career
            case .general: general
            case .yesno: yesno
            }
        }
    }
}

enum TarotCategory: String, CaseIterable, Identifiable, Sendable {
    case general = "Genel"
    case love = "Aşk"
    case career = "Kariyer"
    case yesno = "Evet-Hayır"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "sparkles"
        case .love: "heart.fill"
        case .career: "briefcase.fill"
        case .yesno: "questionmark.circle.fill"
        }
    }

    /// Localize edilmiş görüntüleme adı
    var localizedName: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}
