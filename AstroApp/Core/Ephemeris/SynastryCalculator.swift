import Foundation

/// Iki dogum haritasi arasinda synastry (cross-aspect) hesaplar
struct SynastryCalculator: Sendable {

    /// Iki harita arasindaki synastry sonucunu hesapla
    static func calculate(chart1: BirthChart, chart2: BirthChart) -> SynastryResult {
        let crossAspects = calculateCrossAspects(
            planets1: chart1.planets,
            planets2: chart2.planets
        )

        return SynastryResult(
            chart1: chart1,
            chart2: chart2,
            crossAspects: crossAspects
        )
    }

    /// Iki haritanin gezegenleri arasindaki acilari hesapla
    private static func calculateCrossAspects(
        planets1: [PlanetPosition],
        planets2: [PlanetPosition]
    ) -> [SynastryAspect] {
        var aspects: [SynastryAspect] = []

        // Sadece anlamli gezegenleri kullan (matematiksel noktalar haric)
        let meaningful1 = planets1.filter { Planet.classicPlanets.contains($0.planet) || $0.planet == .northNode || $0.planet == .chiron }
        let meaningful2 = planets2.filter { Planet.classicPlanets.contains($0.planet) || $0.planet == .northNode || $0.planet == .chiron }

        for p1 in meaningful1 {
            for p2 in meaningful2 {
                var diff = abs(p1.longitude - p2.longitude)
                if diff > 180 { diff = 360 - diff }

                for aspectType in AspectType.allCases {
                    let orb = abs(diff - aspectType.rawValue)
                    if orb <= aspectType.orb {
                        let speedDiff = p1.speed - p2.speed
                        let applying: Bool
                        if p1.longitude < p2.longitude {
                            applying = speedDiff > 0
                        } else {
                            applying = speedDiff < 0
                        }

                        aspects.append(SynastryAspect(
                            planet1: p1.planet,
                            planet2: p2.planet,
                            type: aspectType,
                            orb: orb,
                            applying: applying
                        ))
                        break
                    }
                }
            }
        }

        return aspects
    }
}
