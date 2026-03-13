import Foundation
import SwissEphemeris

/// Tutulma tarihlerini hesaplar (yaklasik — Gunes/Ay kavusum ve karsitliklarindan)
struct EclipseCalculator: Sendable {

    /// Belirli bir yil icindeki tutulmalari hesapla
    static func calculate(year: Int) -> [Eclipse] {
        JPLFileManager.setEphemerisPath()

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        var startComp = DateComponents()
        startComp.year = year
        startComp.month = 1
        startComp.day = 1
        guard let yearStart = calendar.date(from: startComp) else { return [] }

        var endComp = DateComponents()
        endComp.year = year + 1
        endComp.month = 1
        endComp.day = 1
        guard let yearEnd = calendar.date(from: endComp) else { return [] }

        var eclipses: [Eclipse] = []
        let step: TimeInterval = 3600 * 12 // 12 saat adim

        var date = yearStart
        var prevSunLon = Coordinate<SwissEphemeris.Planet>(body: .sun, date: date).longitude
        var prevMoonLon = Coordinate<SwissEphemeris.Planet>(body: .moon, date: date).longitude

        while date < yearEnd {
            date = date.addingTimeInterval(step)
            let sunCoord = Coordinate<SwissEphemeris.Planet>(body: .sun, date: date)
            let moonCoord = Coordinate<SwissEphemeris.Planet>(body: .moon, date: date)
            let nodeCoord = Coordinate<LunarNorthNode>(body: .trueNode, date: date)

            let sunLon = sunCoord.longitude
            let moonLon = moonCoord.longitude
            let nodeLon = nodeCoord.longitude

            // Yeni Ay tespiti (Gunes-Ay kavusumu)
            let sunMoonDiff = angleDiff(moonLon, sunLon)
            let prevSunMoonDiff = angleDiff(prevMoonLon, prevSunLon)
            if prevSunMoonDiff > 0 && sunMoonDiff <= 0 || prevSunMoonDiff < -170 && sunMoonDiff > 170 {
                // Yeni Ay — dugum noktasina yakinsa Gunes tutulmasi
                let nodeDistance = min(
                    abs(angleDiff(sunLon, nodeLon)),
                    abs(angleDiff(sunLon, (nodeLon + 180).truncatingRemainder(dividingBy: 360)))
                )
                if nodeDistance < 18 {
                    let eclipseType: EclipseType = nodeDistance < 10 ? .solarTotal : .solarPartial
                    eclipses.append(Eclipse(
                        date: date,
                        type: eclipseType,
                        longitude: sunLon,
                        isSolar: true
                    ))
                }
            }

            // Dolunay tespiti (Gunes-Ay karsitligi)
            let oppDiff = angleDiff(moonLon, (sunLon + 180).truncatingRemainder(dividingBy: 360))
            let prevOppDiff = angleDiff(prevMoonLon, (prevSunLon + 180).truncatingRemainder(dividingBy: 360))
            if prevOppDiff > 0 && oppDiff <= 0 || prevOppDiff < -170 && oppDiff > 170 {
                let nodeDistance = min(
                    abs(angleDiff(moonLon, nodeLon)),
                    abs(angleDiff(moonLon, (nodeLon + 180).truncatingRemainder(dividingBy: 360)))
                )
                if nodeDistance < 12 {
                    let eclipseType: EclipseType = nodeDistance < 5 ? .lunarTotal : .lunarPartial
                    eclipses.append(Eclipse(
                        date: date,
                        type: eclipseType,
                        longitude: moonLon,
                        isSolar: false
                    ))
                }
            }

            prevSunLon = sunLon
            prevMoonLon = moonLon
        }

        return eclipses.sorted { $0.date < $1.date }
    }

    private static func angleDiff(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }
}
