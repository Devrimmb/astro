import Foundation

struct AspectCalculator: Sendable {
    static func calculate(planets: [PlanetPosition]) -> [Aspect] {
        var aspects: [Aspect] = []
        let allPlanets = planets.sorted { p1, p2 in
            Planet.allCases.firstIndex(of: p1.planet)! < Planet.allCases.firstIndex(of: p2.planet)!
        }

        for i in 0..<allPlanets.count {
            for j in (i + 1)..<allPlanets.count {
                let p1 = allPlanets[i]
                let p2 = allPlanets[j]

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

                        aspects.append(Aspect(
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
