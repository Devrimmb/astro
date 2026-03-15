import Foundation

/// Transit gezegen ile natal gezegen arasindaki aci
struct TransitAspect: Identifiable, Sendable {
    let id = UUID()
    let transitPlanet: Planet
    let natalPlanet: Planet
    let type: AspectType
    let orb: Double
    let applying: Bool

    var description: String {
        let applyText = applying ? "yaklaşan" : "ayrılan"
        return "Transit \(transitPlanet.rawValue) \(type.turkishName) Natal \(natalPlanet.rawValue) (\(applyText), \(String(format: "%.1f", orb))°)"
    }
}

/// Belirli bir tarih icin transit hesaplama sonucu
struct TransitReport: Sendable {
    let date: Date
    let transitPositions: [PlanetPosition]
    let aspects: [TransitAspect]
    let natalChart: BirthChart

    /// Onemli transitler (dar orb'lu olanlar once)
    var significantTransits: [TransitAspect] {
        aspects.sorted { $0.orb < $1.orb }
    }

    /// Harmonik transitler
    var harmoniousTransits: [TransitAspect] {
        aspects.filter { $0.type.nature == .harmonik }
    }

    /// Zorlayici transitler
    var challengingTransits: [TransitAspect] {
        aspects.filter { $0.type.nature == .zorlayici }
    }
}

extension AspectType {
    var turkishName: String {
        switch self {
        case .conjunction: "Kavuşum"
        case .sextile: "Sekstil"
        case .square: "Kare"
        case .trine: "Üçgen"
        case .opposition: "Karşıt"
        case .semiSextile: "Yarı-Sekstil"
        case .semiSquare: "Yarı-Kare"
        case .sesquiquadrate: "Oturma-Kare"
        case .quincunx: "Quincunx"
        }
    }

    var symbol: String {
        switch self {
        case .conjunction: "☌"
        case .sextile: "⚹"
        case .square: "□"
        case .trine: "△"
        case .opposition: "☍"
        case .semiSextile: "⚺"
        case .semiSquare: "∠"
        case .sesquiquadrate: "⚼"
        case .quincunx: "⚻"
        }
    }
}
