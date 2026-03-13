import Foundation
import SwissEphemeris

/// Void of Course Moon (Ay Boslukta) donemlerini hesaplar
struct VoidOfCourseCalculator: Sendable {

    /// Belirli bir hafta icindeki VOC donemlerini hesapla
    static func calculate(fromDate: Date, days: Int = 7) -> [VoidOfCourseMoon] {
        JPLFileManager.setEphemerisPath()

        let endDate = fromDate.addingTimeInterval(Double(days) * 86400)
        let step: TimeInterval = 1800 // 30 dakika adim

        var vocPeriods: [VoidOfCourseMoon] = []
        var date = fromDate
        var currentMoonSign = moonSign(at: date)
        var lastAspectDate = date

        while date < endDate {
            date = date.addingTimeInterval(step)
            let moonCoord = Coordinate<SwissEphemeris.Planet>(body: .moon, date: date)
            let newMoonSign = ZodiacSign.from(longitude: moonCoord.longitude)

            // Ay burcu degisti mi?
            if newMoonSign != currentMoonSign {
                // Son aspect'ten burcu degistirme anina kadar VOC
                // Ancak cok kisa VOC'lari (30dk altini) atla
                let vocDuration = date.timeIntervalSince(lastAspectDate)
                if vocDuration > 1800 {
                    vocPeriods.append(VoidOfCourseMoon(
                        startDate: lastAspectDate,
                        endDate: date,
                        fromSign: currentMoonSign,
                        toSign: newMoonSign
                    ))
                }
                currentMoonSign = newMoonSign
                lastAspectDate = date
            }

            // Ay'in diger gezegenlerle aspect yapip yapmadigini kontrol et
            if makesAspect(moonLongitude: moonCoord.longitude, at: date) {
                lastAspectDate = date
            }
        }

        return vocPeriods
    }

    /// Ay bu anda herhangi bir gezegene major aspect yapiyor mu?
    private static func makesAspect(moonLongitude: Double, at date: Date) -> Bool {
        let planets: [SwissEphemeris.Planet] = [.sun, .mercury, .venus, .mars, .jupiter, .saturn]
        let aspectAngles: [Double] = [0, 60, 90, 120, 180]
        let orb = 1.0

        for planet in planets {
            let coord = Coordinate<SwissEphemeris.Planet>(body: planet, date: date)
            var diff = abs(moonLongitude - coord.longitude)
            if diff > 180 { diff = 360 - diff }

            for angle in aspectAngles {
                if abs(diff - angle) <= orb {
                    return true
                }
            }
        }
        return false
    }

    private static func moonSign(at date: Date) -> ZodiacSign {
        let coord = Coordinate<SwissEphemeris.Planet>(body: .moon, date: date)
        return ZodiacSign.from(longitude: coord.longitude)
    }
}
