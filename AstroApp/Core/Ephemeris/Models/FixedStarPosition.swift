import Foundation

/// Sabit yildiz konumu
struct FixedStarPosition: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let turkishName: String
    let longitude: Double
    let latitude: Double
    let magnitude: Double
    let nature: String

    var sign: ZodiacSign {
        ZodiacSign.from(longitude: longitude)
    }

    var degree: Double {
        longitude.truncatingRemainder(dividingBy: 30.0)
    }

    /// Natal gezegene yakin mi? (1° orb)
    func isConjunct(to planetLongitude: Double, orb: Double = 1.0) -> Bool {
        var diff = abs(longitude - planetLongitude)
        if diff > 180 { diff = 360 - diff }
        return diff <= orb
    }
}

/// Sabit yildiz — natal gezegen kavusumlari
struct FixedStarConjunction: Identifiable, Sendable {
    let id = UUID()
    let star: FixedStarPosition
    let planet: Planet
    let orb: Double
}
