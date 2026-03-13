import Foundation

/// Iki harita arasindaki synastry (iliski uyumu) sonucu
struct SynastryResult: Sendable {
    let chart1: BirthChart
    let chart2: BirthChart
    let crossAspects: [SynastryAspect]

    /// Ciro Discepolo metodu ile iliski skoru
    var relationshipScore: RelationshipScoreCalculator.RelationshipScore {
        RelationshipScoreCalculator.calculate(
            chart1: chart1,
            chart2: chart2,
            crossAspects: crossAspects
        )
    }

    /// Genel uyum skoru (0-100) — Discepolo normalize edilmis
    var overallScore: Int {
        relationshipScore.normalizedScore
    }

    /// Orijinal cross-aspect bazli skor (0-100)
    var aspectBasedScore: Int {
        guard !crossAspects.isEmpty else { return 50 }

        var score: Double = 50

        for aspect in crossAspects {
            let weight = aspect.weight
            switch aspect.type.nature {
            case .harmonik:
                score += weight * (1 - aspect.orb / aspect.type.orb)
            case .zorlayici:
                score -= weight * 0.5 * (1 - aspect.orb / aspect.type.orb)
            case .notr:
                score += weight * 0.3 * (1 - aspect.orb / aspect.type.orb)
            }
        }

        return max(0, min(100, Int(score)))
    }

    /// Duygusal uyum (Ay-Ay, Ay-Venus, Ay-Gunes)
    var emotionalScore: Int {
        categoryScore(involving: [.moon, .venus])
    }

    /// Iletisim uyumu (Merkur-Merkur, Merkur-Jupiter)
    var communicationScore: Int {
        categoryScore(involving: [.mercury, .jupiter])
    }

    /// Tutku uyumu (Mars-Venus, Mars-Pluto)
    var passionScore: Int {
        categoryScore(involving: [.mars, .venus, .pluto])
    }

    /// Uzun vadeli uyum (Saturn-Gunes, Saturn-Ay, Jupiter-Gunes)
    var stabilityScore: Int {
        categoryScore(involving: [.saturn, .jupiter, .sun])
    }

    private func categoryScore(involving planets: [Planet]) -> Int {
        let relevant = crossAspects.filter { aspect in
            planets.contains(aspect.planet1) || planets.contains(aspect.planet2)
        }
        guard !relevant.isEmpty else { return 50 }

        var score: Double = 50
        for aspect in relevant {
            let impact = 5.0 * (1 - aspect.orb / aspect.type.orb)
            switch aspect.type.nature {
            case .harmonik: score += impact
            case .zorlayici: score -= impact * 0.5
            case .notr: score += impact * 0.3
            }
        }
        return max(0, min(100, Int(score)))
    }

    /// Onemli cross-aspects (dar orb'lu)
    var keyAspects: [SynastryAspect] {
        crossAspects
            .sorted { $0.orb < $1.orb }
            .prefix(10)
            .map { $0 }
    }
}

/// Synastry'de bir kisinin gezegeni ile diger kisinin gezegeni arasindaki aci
struct SynastryAspect: Identifiable, Sendable {
    let id = UUID()
    let planet1: Planet       // 1. kisinin gezegeni
    let planet2: Planet       // 2. kisinin gezegeni
    let type: AspectType
    let orb: Double
    let applying: Bool

    /// Gezegen agirlik faktoru — Gunes/Ay/Venus/Mars daha onemli
    var weight: Double {
        let personalPlanets: Set<Planet> = [.sun, .moon, .mercury, .venus, .mars]
        let p1Personal = personalPlanets.contains(planet1)
        let p2Personal = personalPlanets.contains(planet2)

        if p1Personal && p2Personal { return 5.0 }
        if p1Personal || p2Personal { return 3.0 }
        return 1.5
    }

    var description: String {
        "\(planet1.rawValue) \(type.symbol) \(planet2.rawValue) (\(String(format: "%.1f", orb))°)"
    }
}
