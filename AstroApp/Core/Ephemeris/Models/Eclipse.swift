import Foundation

/// Tutulma tipi
enum EclipseType: String, Sendable {
    case solarTotal = "Tam Güneş Tutulması"
    case solarPartial = "Kısmi Güneş Tutulması"
    case solarAnnular = "Halkalı Güneş Tutulması"
    case lunarTotal = "Tam Ay Tutulması"
    case lunarPartial = "Kısmi Ay Tutulması"
    case lunarPenumbral = "Yarıgölge Ay Tutulması"
}

/// Tutulma bilgisi
struct Eclipse: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let type: EclipseType
    let longitude: Double
    let isSolar: Bool

    var sign: ZodiacSign {
        ZodiacSign.from(longitude: longitude)
    }

    var degree: Double {
        longitude.truncatingRemainder(dividingBy: 30.0)
    }

    var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Bu tutulma natal haritadaki bir gezegene yakin mi?
    func affectsNatalPlanet(_ planets: [PlanetPosition], orb: Double = 3.0) -> [Planet] {
        planets.compactMap { pos in
            var diff = abs(longitude - pos.longitude)
            if diff > 180 { diff = 360 - diff }
            return diff <= orb ? pos.planet : nil
        }
    }
}
