import Foundation

enum AspectType: Double, CaseIterable, Codable, Sendable {
    // Major açılar (önce tanımlanmalı — allCases sırası önemli)
    case conjunction = 0
    case sextile = 60
    case square = 90
    case trine = 120
    case opposition = 180
    // Minor açılar
    case semiSextile = 30
    case semiSquare = 45
    case sesquiquadrate = 135
    case quincunx = 150

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
        case .semiSextile: 2
        case .semiSquare: 2
        case .sesquiquadrate: 2
        case .quincunx: 3
        }
    }

    var nature: Nature {
        switch self {
        case .conjunction: .notr
        case .sextile, .trine: .harmonik
        case .square, .opposition: .zorlayici
        case .semiSextile: .notr
        case .semiSquare, .sesquiquadrate: .zorlayici
        case .quincunx: .notr
        }
    }

    var isMajor: Bool {
        switch self {
        case .conjunction, .sextile, .square, .trine, .opposition: true
        default: false
        }
    }
}

struct Aspect: Codable, Sendable {
    let point1: ChartPoint
    let point2: ChartPoint
    let type: AspectType
    let orb: Double
    let applying: Bool

    // MARK: - Geriye uyumluluk

    /// Eski kod için: planet1 erişimi (ASC/MC için nil döner)
    var planet1: Planet {
        if case .planet(let p) = point1 { return p }
        // Fallback — eski kod planet1'i direkt kullanıyordu
        return .sun
    }

    /// Eski kod için: planet2 erişimi (ASC/MC için nil döner)
    var planet2: Planet {
        if case .planet(let p) = point2 { return p }
        return .sun
    }

    // MARK: - Convenience init (eski format uyumu)

    init(point1: ChartPoint, point2: ChartPoint, type: AspectType, orb: Double, applying: Bool) {
        self.point1 = point1
        self.point2 = point2
        self.type = type
        self.orb = orb
        self.applying = applying
    }

    /// Eski API uyumluluğu — planet bazlı init
    init(planet1: Planet, planet2: Planet, type: AspectType, orb: Double, applying: Bool) {
        self.point1 = .planet(planet1)
        self.point2 = .planet(planet2)
        self.type = type
        self.orb = orb
        self.applying = applying
    }

    // MARK: - Custom Codable (geriye uyumluluk)

    private enum CodingKeys: String, CodingKey {
        // Yeni format
        case point1, point2, type, orb, applying
        // Eski format
        case planet1, planet2
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(point1, forKey: .point1)
        try container.encode(point2, forKey: .point2)
        try container.encode(type, forKey: .type)
        try container.encode(orb, forKey: .orb)
        try container.encode(applying, forKey: .applying)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AspectType.self, forKey: .type)
        orb = try container.decode(Double.self, forKey: .orb)
        applying = try container.decode(Bool.self, forKey: .applying)

        // Yeni format dene
        if let p1 = try? container.decode(ChartPoint.self, forKey: .point1),
           let p2 = try? container.decode(ChartPoint.self, forKey: .point2) {
            point1 = p1
            point2 = p2
        }
        // Eski format (planet1/planet2)
        else if let pl1 = try? container.decode(Planet.self, forKey: .planet1),
                let pl2 = try? container.decode(Planet.self, forKey: .planet2) {
            point1 = .planet(pl1)
            point2 = .planet(pl2)
        }
        // Hiçbiri yoksa hata
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .point1,
                in: container,
                debugDescription: "Aspect point bilgisi bulunamadı"
            )
        }
    }
}
