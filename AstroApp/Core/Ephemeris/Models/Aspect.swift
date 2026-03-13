import Foundation

enum AspectType: Double, CaseIterable, Codable, Sendable {
    case conjunction = 0
    case sextile = 60
    case square = 90
    case trine = 120
    case opposition = 180

    enum Nature: Codable, Sendable {
        case harmonik
        case zorlayici
        case notr
    }

    var orb: Double {
        switch self {
        case .conjunction: 8
        case .sextile: 6
        case .square: 7
        case .trine: 8
        case .opposition: 8
        }
    }

    var nature: Nature {
        switch self {
        case .conjunction: .notr
        case .sextile, .trine: .harmonik
        case .square, .opposition: .zorlayici
        }
    }
}

struct Aspect: Codable, Sendable {
    let planet1: Planet
    let planet2: Planet
    let type: AspectType
    let orb: Double
    let applying: Bool
}
