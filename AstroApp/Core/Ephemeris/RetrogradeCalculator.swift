import Foundation
import SwissEphemeris

/// Retrograde donemlerini hesaplar
struct RetrogradeCalculator: Sendable {

    /// Retrograde donemi
    struct RetrogradePeriod: Identifiable, Sendable {
        let id = UUID()
        let planet: AstroApp.Planet
        let startDate: Date
        let endDate: Date
        let startSign: ZodiacSign
        let endSign: ZodiacSign

        var isActive: Bool {
            let now = Date.now
            return now >= startDate && now <= endDate
        }

        var startText: String { formatDate(startDate) }
        var endText: String { formatDate(endDate) }

        var durationDays: Int {
            Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        private func formatDate(_ date: Date) -> String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "tr_TR")
            f.dateFormat = "d MMMM yyyy"
            return f.string(from: date)
        }
    }

    /// Belirli bir yil icinde tum retrograde donemleri hesapla
    static func calculate(year: Int) -> [RetrogradePeriod] {
        JPLFileManager.setEphemerisPath()

        let planets: [(AstroApp.Planet, SwissEphemeris.Planet)] = [
            (.mercury, .mercury),
            (.venus, .venus),
            (.mars, .mars),
            (.jupiter, .jupiter),
            (.saturn, .saturn),
            (.uranus, .uranus),
            (.neptune, .neptune),
            (.pluto, .pluto),
        ]

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

        var periods: [RetrogradePeriod] = []

        for (appPlanet, sePlanet) in planets {
            let step: TimeInterval = appPlanet == .mercury ? 3600 * 6 : 3600 * 24 // Merkur icin 6 saat, diger icin 1 gun
            var date = yearStart
            var wasRetro = Coordinate<SwissEphemeris.Planet>(body: sePlanet, date: date).speedLongitude < 0
            var retroStart: Date?

            if wasRetro {
                retroStart = date
            }

            while date < yearEnd {
                date = date.addingTimeInterval(step)
                let coord = Coordinate<SwissEphemeris.Planet>(body: sePlanet, date: date)
                let isRetro = coord.speedLongitude < 0

                if isRetro && !wasRetro {
                    // Retrograde basladi
                    retroStart = date
                } else if !isRetro && wasRetro, let start = retroStart {
                    // Retrograde bitti
                    let startCoord = Coordinate<SwissEphemeris.Planet>(body: sePlanet, date: start)
                    let endCoord = Coordinate<SwissEphemeris.Planet>(body: sePlanet, date: date)

                    periods.append(RetrogradePeriod(
                        planet: appPlanet,
                        startDate: start,
                        endDate: date,
                        startSign: ZodiacSign.from(longitude: startCoord.longitude),
                        endSign: ZodiacSign.from(longitude: endCoord.longitude)
                    ))
                    retroStart = nil
                }

                wasRetro = isRetro
            }

            // Yil sonunda hala retrodaysa
            if let start = retroStart {
                let startCoord = Coordinate<SwissEphemeris.Planet>(body: sePlanet, date: start)
                periods.append(RetrogradePeriod(
                    planet: appPlanet,
                    startDate: start,
                    endDate: yearEnd,
                    startSign: ZodiacSign.from(longitude: startCoord.longitude),
                    endSign: ZodiacSign.from(longitude: startCoord.longitude)
                ))
            }
        }

        return periods.sorted { $0.startDate < $1.startDate }
    }
}
