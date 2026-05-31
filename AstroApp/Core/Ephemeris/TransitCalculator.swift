import Foundation
import SwissEphemeris

/// Transit gezegen pozisyonlarini hesaplar ve natal haritayla karsilastirir
struct TransitCalculator: Sendable {

    /// Belirli bir tarih icin transit raporu olustur
    static func calculate(
        natalChart: BirthChart,
        transitDate: Date
    ) -> TransitReport {
        JPLFileManager.setEphemerisPath()

        var transitPositions = calculatePositions(for: transitDate)

        // Transit gezegenlerini natal ev sistemine göre ata
        for i in 0..<transitPositions.count {
            transitPositions[i].house = houseForLongitude(
                transitPositions[i].longitude, houses: natalChart.houses
            )
        }

        let aspects = calculateCrossAspects(
            transitPlanets: transitPositions,
            natalPlanets: natalChart.planets
        )

        return TransitReport(
            date: transitDate,
            transitPositions: transitPositions,
            aspects: aspects,
            natalChart: natalChart
        )
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

    /// Belirli bir tarih icin gezegen pozisyonlarini hesapla
    static func calculatePositions(for date: Date) -> [PlanetPosition] {
        JPLFileManager.setEphemerisPath()

        let sunCoord = Coordinate<SwissEphemeris.Planet>(body: .sun, date: date)
        let moonCoord = Coordinate<SwissEphemeris.Planet>(body: .moon, date: date)
        let mercuryCoord = Coordinate<SwissEphemeris.Planet>(body: .mercury, date: date)
        let venusCoord = Coordinate<SwissEphemeris.Planet>(body: .venus, date: date)
        let marsCoord = Coordinate<SwissEphemeris.Planet>(body: .mars, date: date)
        let jupiterCoord = Coordinate<SwissEphemeris.Planet>(body: .jupiter, date: date)
        let saturnCoord = Coordinate<SwissEphemeris.Planet>(body: .saturn, date: date)
        let uranusCoord = Coordinate<SwissEphemeris.Planet>(body: .uranus, date: date)
        let neptuneCoord = Coordinate<SwissEphemeris.Planet>(body: .neptune, date: date)
        let plutoCoord = Coordinate<SwissEphemeris.Planet>(body: .pluto, date: date)

        let coordMap: [(AstroApp.Planet, Double, Double, Double)] = [
            (.sun, sunCoord.longitude, sunCoord.latitude, sunCoord.speedLongitude),
            (.moon, moonCoord.longitude, moonCoord.latitude, moonCoord.speedLongitude),
            (.mercury, mercuryCoord.longitude, mercuryCoord.latitude, mercuryCoord.speedLongitude),
            (.venus, venusCoord.longitude, venusCoord.latitude, venusCoord.speedLongitude),
            (.mars, marsCoord.longitude, marsCoord.latitude, marsCoord.speedLongitude),
            (.jupiter, jupiterCoord.longitude, jupiterCoord.latitude, jupiterCoord.speedLongitude),
            (.saturn, saturnCoord.longitude, saturnCoord.latitude, saturnCoord.speedLongitude),
            (.uranus, uranusCoord.longitude, uranusCoord.latitude, uranusCoord.speedLongitude),
            (.neptune, neptuneCoord.longitude, neptuneCoord.latitude, neptuneCoord.speedLongitude),
            (.pluto, plutoCoord.longitude, plutoCoord.latitude, plutoCoord.speedLongitude),
        ]

        return coordMap.map { planet, lon, lat, speed in
            PlanetPosition(planet: planet, longitude: lon, latitude: lat, speed: speed, house: 0)
        }
    }

    /// Transit gezegenler ile natal gezegenler arasindaki acilari hesapla
    private static func calculateCrossAspects(
        transitPlanets: [PlanetPosition],
        natalPlanets: [PlanetPosition]
    ) -> [TransitAspect] {
        var aspects: [TransitAspect] = []

        // Transit icin daha dar orb kullan
        let transitOrbFactor = 0.75

        for transit in transitPlanets {
            for natal in natalPlanets {
                // Sadece klasik gezegenler arasi aspect hesapla
                guard Planet.classicPlanets.contains(natal.planet) else { continue }

                var diff = abs(transit.longitude - natal.longitude)
                if diff > 180 { diff = 360 - diff }

                for aspectType in AspectType.allCases {
                    let orbLimit = aspectType.orb * transitOrbFactor
                    let orb = abs(diff - aspectType.rawValue)
                    if orb <= orbLimit {
                        let speedDiff = transit.speed - natal.speed
                        let applying: Bool
                        if transit.longitude < natal.longitude {
                            applying = speedDiff > 0
                        } else {
                            applying = speedDiff < 0
                        }

                        aspects.append(TransitAspect(
                            transitPlanet: transit.planet,
                            natalPlanet: natal.planet,
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
