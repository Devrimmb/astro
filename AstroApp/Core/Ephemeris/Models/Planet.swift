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
}
