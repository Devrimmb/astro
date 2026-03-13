import Foundation

/// Iki haritanin orta noktalarindan composite harita olusturur
struct CompositeChartCalculator: Sendable {

    static func calculate(chart1: BirthChart, chart2: BirthChart) -> CompositeChart {
        // Ortak gezegenleri bul ve midpoint hesapla
        var compositePlanets: [PlanetPosition] = []

        for planet in Planet.classicPlanets {
            guard let p1 = chart1.planets.first(where: { $0.planet == planet }),
                  let p2 = chart2.planets.first(where: { $0.planet == planet }) else { continue }

            let midLon = midpoint(p1.longitude, p2.longitude)
            let midLat = (p1.latitude + p2.latitude) / 2
            let midSpeed = (p1.speed + p2.speed) / 2

            compositePlanets.append(PlanetPosition(
                planet: planet,
                longitude: midLon,
                latitude: midLat,
                speed: midSpeed,
                house: 0
            ))
        }

        // Composite ASC = iki ASC'nin midpoint'i
        let asc1 = chart1.houses.first(where: { $0.id == 1 })?.cusp ?? 0
        let asc2 = chart2.houses.first(where: { $0.id == 1 })?.cusp ?? 0
        let compositeAsc = midpoint(asc1, asc2)

        // Equal house sistemi
        var houses: [House] = []
        for i in 0..<12 {
            let cusp = (compositeAsc + Double(i) * 30.0).truncatingRemainder(dividingBy: 360)
            houses.append(House(id: i + 1, cusp: cusp, planets: []))
        }

        // Gezegenlerin ev konumlarini ata
        for i in 0..<compositePlanets.count {
            compositePlanets[i].house = houseForLongitude(compositePlanets[i].longitude, houses: houses)
        }

        let aspects = AspectCalculator.calculate(planets: compositePlanets)

        return CompositeChart(
            planets: compositePlanets,
            houses: houses,
            aspects: aspects
        )
    }

    /// Iki aci arasindaki midpoint (kisa yol)
    private static func midpoint(_ a: Double, _ b: Double) -> Double {
        var diff = b - a
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        var mid = a + diff / 2
        if mid < 0 { mid += 360 }
        if mid >= 360 { mid -= 360 }
        return mid
    }

    private static func houseForLongitude(_ longitude: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let current = houses[i].cusp
            let next = i + 1 < houses.count ? houses[i + 1].cusp : houses[0].cusp + 360
            var adjustedNext = next
            if adjustedNext < current { adjustedNext += 360 }
            var adjustedLon = longitude
            if adjustedLon < current { adjustedLon += 360 }
            if adjustedLon >= current && adjustedLon < adjustedNext {
                return houses[i].id
            }
        }
        return 1
    }
}
