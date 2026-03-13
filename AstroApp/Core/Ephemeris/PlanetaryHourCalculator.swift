import Foundation

/// Gezegen saatlerini hesaplar (Chaldean sirasi)
struct PlanetaryHourCalculator: Sendable {

    /// Chaldean sirasi: Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon
    private static let chaldeanOrder: [Planet] = [
        .saturn, .jupiter, .mars, .sun, .venus, .mercury, .moon
    ]

    /// Haftanin gunlerine gore baslangicdaki gezegen (gun yoneticisi)
    /// Pazar=Gunes, Pazartesi=Ay, Sali=Mars, Carsamba=Merkur, Persembe=Jupiter, Cuma=Venus, Cumartesi=Saturn
    private static let dayRulers: [Int: Planet] = [
        1: .sun,      // Pazar
        2: .moon,     // Pazartesi
        3: .mars,     // Sali
        4: .mercury,  // Carsamba
        5: .jupiter,  // Persembe
        6: .venus,    // Cuma
        7: .saturn,   // Cumartesi
    ]

    /// Belirli bir gun ve konum icin gezegen saatlerini hesapla
    static func calculate(date: Date, latitude: Double, longitude: Double) -> DailyPlanetaryHours {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        // Yaklasik gun dogumu ve batimi (basitlesitirilmis)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 172
        let declination = 23.44 * sin(2 * .pi * Double(dayOfYear - 81) / 365.0)
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180

        let cosHourAngle = -tan(latRad) * tan(decRad)
        let hourAngle: Double
        if cosHourAngle < -1 {
            hourAngle = .pi // Yarim gece gunes
        } else if cosHourAngle > 1 {
            hourAngle = 0 // Polar gece
        } else {
            hourAngle = acos(cosHourAngle)
        }

        let dayLengthHours = 2 * hourAngle * 12 / .pi
        let nightLengthHours = 24 - dayLengthHours

        // Saat 12:00'yi (gunes oglen) baz al
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let sunriseHour = 12.0 - dayLengthHours / 2
        let sunsetHour = 12.0 + dayLengthHours / 2

        let sunrise = noon.addingTimeInterval((sunriseHour - 12.0) * 3600)
        let sunset = noon.addingTimeInterval((sunsetHour - 12.0) * 3600)

        let dayHourLength = dayLengthHours * 3600 / 12.0
        let nightHourLength = nightLengthHours * 3600 / 12.0

        // Gunun yoneticisini bul
        let weekday = calendar.component(.weekday, from: date)
        let dayRuler = dayRulers[weekday] ?? .sun
        let startIndex = chaldeanOrder.firstIndex(of: dayRuler) ?? 0

        var hours: [PlanetaryHour] = []

        // Gunduz 12 saat
        for i in 0..<12 {
            let planetIndex = (startIndex + i) % 7
            hours.append(PlanetaryHour(
                hourNumber: i + 1,
                planet: chaldeanOrder[planetIndex],
                startTime: sunrise.addingTimeInterval(Double(i) * dayHourLength),
                endTime: sunrise.addingTimeInterval(Double(i + 1) * dayHourLength),
                isDayHour: true
            ))
        }

        // Gece 12 saat
        for i in 0..<12 {
            let planetIndex = (startIndex + 12 + i) % 7
            hours.append(PlanetaryHour(
                hourNumber: i + 1,
                planet: chaldeanOrder[planetIndex],
                startTime: sunset.addingTimeInterval(Double(i) * nightHourLength),
                endTime: sunset.addingTimeInterval(Double(i + 1) * nightHourLength),
                isDayHour: false
            ))
        }

        return DailyPlanetaryHours(date: date, hours: hours)
    }
}
