import Foundation

struct AspectCalculator: Sendable {

    /// Gezegen + ASC/MC dahil tüm açıları hesaplar
    static func calculate(planets: [PlanetPosition], houses: [House] = []) -> [Aspect] {
        // Hesaplama noktalarını oluştur: (ChartPoint, longitude, speed)
        var points: [(point: ChartPoint, longitude: Double, speed: Double)] = []

        for pos in planets {
            points.append((.planet(pos.planet), pos.longitude, pos.speed))
        }

        // ASC (1. ev cusp) ve MC (10. ev cusp) ekle
        if let ascHouse = houses.first(where: { $0.id == 1 }) {
            points.append((.ascendant, ascHouse.cusp, 0))
        }
        if let mcHouse = houses.first(where: { $0.id == 10 }) {
            points.append((.midheaven, mcHouse.cusp, 0))
        }

        var aspects: [Aspect] = []

        for i in 0..<points.count {
            for j in (i + 1)..<points.count {
                let p1 = points[i]
                let p2 = points[j]

                var diff = abs(p1.longitude - p2.longitude)
                if diff > 180 { diff = 360 - diff }

                // En iyi eşleşen açı tipini bul (normalized orb'a göre)
                var bestAspect: (type: AspectType, orb: Double)?

                for aspectType in AspectType.allCases {
                    let orb = abs(diff - aspectType.rawValue)
                    if orb <= aspectType.orb {
                        let normalizedOrb = orb / aspectType.orb
                        if bestAspect == nil || normalizedOrb < (bestAspect!.orb / bestAspect!.type.orb) {
                            bestAspect = (aspectType, orb)
                        }
                    }
                }

                if let best = bestAspect {
                    let speedDiff = p1.speed - p2.speed
                    let applying: Bool
                    if p1.longitude < p2.longitude {
                        applying = speedDiff > 0
                    } else {
                        applying = speedDiff < 0
                    }

                    aspects.append(Aspect(
                        point1: p1.point,
                        point2: p2.point,
                        type: best.type,
                        orb: best.orb,
                        applying: applying
                    ))
                }
            }
        }
        return aspects
    }
}
