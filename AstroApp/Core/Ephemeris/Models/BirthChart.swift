import Foundation

struct BirthChart: Codable, Sendable {
    let birthDate: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    var planets: [PlanetPosition]
    var houses: [House]
    var aspects: [Aspect]

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var sunSign: ZodiacSign? {
        planets.first(where: { $0.planet == .sun })?.sign
    }

    var moonSign: ZodiacSign? {
        planets.first(where: { $0.planet == .moon })?.sign
    }

    var ascendant: ZodiacSign? {
        houses.first(where: { $0.id == 1 })?.sign
    }

    private static let planetWeights: [Planet: Double] = [
        .sun: 2.5, .moon: 2.5,
        .mercury: 1.5, .venus: 1.5, .mars: 1.5,
        .jupiter: 1.0, .saturn: 1.0,
        .uranus: 0.5, .neptune: 0.5, .pluto: 0.5
    ]

    var elementBalance: [ZodiacSign.Element: Double] {
        var scores: [ZodiacSign.Element: Double] = [:]
        for position in planets {
            guard let weight = BirthChart.planetWeights[position.planet] else { continue }
            scores[position.sign.element, default: 0] += weight
        }
        // Yükselen burç: 2.0 puan
        if let ascCusp = houses.first(where: { $0.id == 1 })?.cusp {
            let ascSign = ZodiacSign.from(longitude: ascCusp)
            scores[ascSign.element, default: 0] += 2.0
        }
        return scores
    }

    // MARK: - Burç Yansıması

    struct DominantSignExpression: Sendable {
        let element: ZodiacSign.Element
        let sign: ZodiacSign
        let matchCount: Int
    }

    /// BASKIN element (≥6.0 puan) + 8 anahtar noktadan ≥3'ü aynı burçta + o burç baskın elementin burcu ise döner.
    /// 8 anahtar nokta: Güneş, Ay, Merkür, Venüs, Mars, Jüpiter, Satürn, ASC
    var dominantSignExpression: DominantSignExpression? {
        let elements = elementBalance

        // Baskın element ≥6.0 olmalı
        guard let dominant = elements.max(by: { $0.value < $1.value }),
              dominant.value >= 6.0 else { return nil }

        let dominantElement = dominant.key
        let keyPlanets: Set<Planet> = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn]

        // 8 anahtar noktanın burç dağılımı
        var signCounts: [ZodiacSign: Int] = [:]
        for position in planets where keyPlanets.contains(position.planet) {
            signCounts[position.sign, default: 0] += 1
        }
        if let ascCusp = houses.first(where: { $0.id == 1 })?.cusp {
            signCounts[ZodiacSign.from(longitude: ascCusp), default: 0] += 1
        }

        // Baskın elementin burçları + ≥3 koşulu
        let qualifying = signCounts.filter { $0.value >= 3 && $0.key.element == dominantElement }
        guard !qualifying.isEmpty else { return nil }

        // En fazla gezegen olan burç; eşitlikte Güneş/Ay burcu öncelikli
        let sunSign  = planets.first(where: { $0.planet == .sun  })?.sign
        let moonSign = planets.first(where: { $0.planet == .moon })?.sign

        let best = qualifying.max { a, b in
            if a.value != b.value { return a.value < b.value }
            if a.key == sunSign || a.key == moonSign { return false }
            return true
        }!

        return DominantSignExpression(element: dominantElement, sign: best.key, matchCount: best.value)
    }

    var modalityBalance: [ZodiacSign.Modality: Int] {
        var counts: [ZodiacSign.Modality: Int] = [:]
        for position in planets {
            guard BirthChart.planetWeights[position.planet] != nil else { continue }
            counts[position.sign.modality, default: 0] += 1
        }
        return counts
    }

    var dominantElement: ZodiacSign.Element? {
        elementBalance.max(by: { $0.value < $1.value })?.key
    }

    var dominantModality: ZodiacSign.Modality? {
        modalityBalance.max(by: { $0.value < $1.value })?.key
    }
}
