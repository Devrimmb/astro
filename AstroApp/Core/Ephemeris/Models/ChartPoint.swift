import Foundation

/// Haritadaki herhangi bir noktayı temsil eder: gezegen, ASC veya MC.
/// Aspect hesaplamalarında kullanılır.
enum ChartPoint: Hashable, Sendable {
    case planet(Planet)
    case ascendant
    case midheaven

    var name: String {
        switch self {
        case .planet(let p): p.name
        case .ascendant: LanguageManager.localized("Yükselen")
        case .midheaven: "MC"
        }
    }

    var shortName: String {
        switch self {
        case .planet(let p):
            switch p {
            case .sun: "Gü"
            case .moon: "Ay"
            case .mercury: "Me"
            case .venus: "Ve"
            case .mars: "Ma"
            case .jupiter: "Jü"
            case .saturn: "Sa"
            case .uranus: "Ur"
            case .neptune: "Ne"
            case .pluto: "Pl"
            case .northNode: "KD"
            case .chiron: "Ch"
            case .lilith: "Li"
            case .partOfFortune: "TN"
            case .ceres: "Ce"
            case .pallas: "Pa"
            case .juno: "Ju"
            case .vesta: "Vs"
            }
        case .ascendant: "ASC"
        case .midheaven: "MC"
        }
    }

    var glyph: String {
        switch self {
        case .planet(let p):
            switch p {
            case .sun: "☉"
            case .moon: "☽"
            case .mercury: "☿"
            case .venus: "♀"
            case .mars: "♂"
            case .jupiter: "♃"
            case .saturn: "♄"
            case .uranus: "♅"
            case .neptune: "♆"
            case .pluto: "♇"
            case .northNode: "☊"
            case .chiron: "⚷"
            case .lilith: "⚸"
            case .partOfFortune: "⊕"
            case .ceres: "⚳"
            case .pallas: "⚴"
            case .juno: "⚵"
            case .vesta: "⚶"
            }
        case .ascendant: "ASC"
        case .midheaven: "MC"
        }
    }

    /// Aspect grid'de kullanılacak ana noktalar
    static var gridPoints: [ChartPoint] {
        [
            .planet(.sun), .planet(.moon), .planet(.mercury), .planet(.venus),
            .planet(.mars), .planet(.jupiter), .planet(.saturn), .planet(.uranus),
            .planet(.neptune), .planet(.pluto), .planet(.northNode), .planet(.chiron),
            .ascendant, .midheaven
        ]
    }
}

// MARK: - Codable

extension ChartPoint: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, planet
    }

    private enum PointType: String, Codable {
        case planet, ascendant, midheaven
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .planet(let p):
            try container.encode(PointType.planet, forKey: .type)
            try container.encode(p, forKey: .planet)
        case .ascendant:
            try container.encode(PointType.ascendant, forKey: .type)
        case .midheaven:
            try container.encode(PointType.midheaven, forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let pointType = try container.decode(PointType.self, forKey: .type)
        switch pointType {
        case .planet:
            let planet = try container.decode(Planet.self, forKey: .planet)
            self = .planet(planet)
        case .ascendant:
            self = .ascendant
        case .midheaven:
            self = .midheaven
        }
    }
}
