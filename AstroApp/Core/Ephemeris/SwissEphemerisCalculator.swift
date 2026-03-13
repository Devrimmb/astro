import Foundation
import SwissEphemeris

struct SwissEphemerisCalculator: EphemerisCalculating, Sendable {

    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart {
        // JPL efemeris dosya yolunu ayarla
        JPLFileManager.setEphemerisPath()

        let utcDate = date

        // Gezegen pozisyonlarını hesapla (SwissEphemeris.Planet kullanarak)
        let sunCoord = Coordinate<SwissEphemeris.Planet>(body: .sun, date: utcDate)
        let moonCoord = Coordinate<SwissEphemeris.Planet>(body: .moon, date: utcDate)
        let mercuryCoord = Coordinate<SwissEphemeris.Planet>(body: .mercury, date: utcDate)
        let venusCoord = Coordinate<SwissEphemeris.Planet>(body: .venus, date: utcDate)
        let marsCoord = Coordinate<SwissEphemeris.Planet>(body: .mars, date: utcDate)
        let jupiterCoord = Coordinate<SwissEphemeris.Planet>(body: .jupiter, date: utcDate)
        let saturnCoord = Coordinate<SwissEphemeris.Planet>(body: .saturn, date: utcDate)
        let uranusCoord = Coordinate<SwissEphemeris.Planet>(body: .uranus, date: utcDate)
        let neptuneCoord = Coordinate<SwissEphemeris.Planet>(body: .neptune, date: utcDate)
        let plutoCoord = Coordinate<SwissEphemeris.Planet>(body: .pluto, date: utcDate)
        let nodeCoord = Coordinate<LunarNorthNode>(body: .trueNode, date: utcDate)
        let chironCoord = Coordinate<Asteroid>(body: .chiron, date: utcDate)

        // Asteroidler
        let ceresCoord = Coordinate<Asteroid>(body: .ceres, date: utcDate)
        let pallasCoord = Coordinate<Asteroid>(body: .pallas, date: utcDate)
        let junoCoord = Coordinate<Asteroid>(body: .juno, date: utcDate)
        let vestaCoord = Coordinate<Asteroid>(body: .vesta, date: utcDate)

        // Ev hesaplama (Placidus)
        let cusps = HouseCusps(date: utcDate, latitude: latitude, longitude: longitude, houseSystem: .placidus)

        // House cusp'lardan House array'i oluştur — Cusp.tropical.value ekliptik boylamı verir
        let cuspList = [
            cusps.first, cusps.second, cusps.third,
            cusps.fourth, cusps.fifth, cusps.sixth,
            cusps.seventh, cusps.eighth, cusps.ninth,
            cusps.tenth, cusps.eleventh, cusps.twelfth
        ]

        var houses: [House] = []
        for (index, cusp) in cuspList.enumerated() {
            houses.append(House(id: index + 1, cusp: cusp.tropical.value, planets: []))
        }

        // Lilith (Mean Black Moon) — Kuzey Dugum'un karsiti degil, ayri hesap
        // Mean Lilith ≈ Mean Lunar Apogee
        let lilithCoord = Coordinate<LunarApogee>(body: .mean, date: utcDate)

        // Part of Fortune = ASC + Moon - Sun (gunduz haritasi)
        // Gece haritasinda: ASC + Sun - Moon
        let ascLongitude = cuspList[0].tropical.value
        let sunLon = sunCoord.longitude
        let moonLon = moonCoord.longitude
        let isDayChart = sunLon > ascLongitude - 180 && sunLon < ascLongitude
        let pofLongitude: Double
        if isDayChart {
            pofLongitude = (ascLongitude + moonLon - sunLon).truncatingRemainder(dividingBy: 360)
        } else {
            pofLongitude = (ascLongitude + sunLon - moonLon).truncatingRemainder(dividingBy: 360)
        }
        let adjustedPof = pofLongitude < 0 ? pofLongitude + 360 : pofLongitude

        // PlanetPosition'lara dönüştür
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
            (.northNode, nodeCoord.longitude, nodeCoord.latitude, nodeCoord.speedLongitude),
            (.chiron, chironCoord.longitude, chironCoord.latitude, chironCoord.speedLongitude),
            (.lilith, lilithCoord.longitude, lilithCoord.latitude, lilithCoord.speedLongitude),
            (.partOfFortune, adjustedPof, 0, 0),
            (.ceres, ceresCoord.longitude, ceresCoord.latitude, ceresCoord.speedLongitude),
            (.pallas, pallasCoord.longitude, pallasCoord.latitude, pallasCoord.speedLongitude),
            (.juno, junoCoord.longitude, junoCoord.latitude, junoCoord.speedLongitude),
            (.vesta, vestaCoord.longitude, vestaCoord.latitude, vestaCoord.speedLongitude),
        ]

        var planets: [PlanetPosition] = []
        for (planet, lon, lat, speed) in coordMap {
            let houseNum = houseForLongitude(lon, houses: houses)
            planets.append(PlanetPosition(
                planet: planet,
                longitude: lon,
                latitude: lat,
                speed: speed,
                house: houseNum
            ))
        }

        let aspects = AspectCalculator.calculate(planets: planets)

        return BirthChart(
            birthDate: date,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }

    private func houseForLongitude(_ longitude: Double, houses: [House]) -> Int {
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
