import Foundation

enum Planet: String, CaseIterable, Codable, Sendable {
    case sun = "Güneş"
    case moon = "Ay"
    case mercury = "Merkür"
    case venus = "Venüs"
    case mars = "Mars"
    case jupiter = "Jüpiter"
    case saturn = "Satürn"
    case uranus = "Uranüs"
    case neptune = "Neptün"
    case pluto = "Plüton"
    case northNode = "Kuzey Düğüm"
    case chiron = "Chiron"
    case lilith = "Lilith"
    case partOfFortune = "Talih Noktası"
    case ceres = "Ceres"
    case pallas = "Pallas"
    case juno = "Juno"
    case vesta = "Vesta"

    /// Lokalize edilmiş gezegen adı
    var name: String {
        switch self {
        case .sun: LanguageManager.localized( "Güneş")
        case .moon: LanguageManager.localized( "Ay")
        case .mercury: LanguageManager.localized( "Merkür")
        case .venus: LanguageManager.localized( "Venüs")
        case .mars: LanguageManager.localized( "Mars")
        case .jupiter: LanguageManager.localized( "Jüpiter")
        case .saturn: LanguageManager.localized( "Satürn")
        case .uranus: LanguageManager.localized( "Uranüs")
        case .neptune: LanguageManager.localized( "Neptün")
        case .pluto: LanguageManager.localized( "Plüton")
        case .northNode: LanguageManager.localized( "Kuzey Düğüm")
        case .chiron: LanguageManager.localized( "Chiron")
        case .lilith: LanguageManager.localized( "Lilith")
        case .partOfFortune: LanguageManager.localized( "Talih Noktası")
        case .ceres: LanguageManager.localized( "Ceres")
        case .pallas: LanguageManager.localized( "Pallas")
        case .juno: LanguageManager.localized( "Juno")
        case .vesta: LanguageManager.localized( "Vesta")
        }
    }

    /// Astrolojik sembol — çark, listeler ve paylaşım kartları hep buradan okur
    var glyph: String {
        switch self {
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
    }

    var identifier: String {
        switch self {
        case .sun: "sun"
        case .moon: "moon"
        case .mercury: "mercury"
        case .venus: "venus"
        case .mars: "mars"
        case .jupiter: "jupiter"
        case .saturn: "saturn"
        case .uranus: "uranus"
        case .neptune: "neptune"
        case .pluto: "pluto"
        case .northNode: "north_node"
        case .chiron: "chiron"
        case .lilith: "lilith"
        case .partOfFortune: "part_of_fortune"
        case .ceres: "ceres"
        case .pallas: "pallas"
        case .juno: "juno"
        case .vesta: "vesta"
        }
    }

    /// Klasik gezegenler (transit ve aspect hesaplamalarinda kullanilir)
    static var classicPlanets: [Planet] {
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto]
    }

    /// Tum gercek gok cisimleri (matematiksel noktalar haric)
    static var celestialBodies: [Planet] {
        [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto, .northNode, .chiron, .lilith]
    }

    /// Asteroidler
    static var asteroids: [Planet] {
        [.ceres, .pallas, .juno, .vesta]
    }

    /// Widget ve UI'da kullanilan metin sembolu (emoji degil, Unicode text)
    var widgetSymbol: String {
        switch self {
        case .sun:     "☉"
        case .moon:    "☽"
        case .mercury: "☿"
        case .venus:   "♀"
        case .mars:    "♂"
        case .jupiter: "♃"
        case .saturn:  "♄"
        case .uranus:  "⛢"
        case .neptune: "♆"
        case .pluto:   "♇"
        default:       "·"
        }
    }
}
