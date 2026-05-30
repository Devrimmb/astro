import Foundation

// MARK: - Burç Enum (Widget-local)

enum WidgetZodiacSign: String, CaseIterable {
    case aries = "Koç"
    case taurus = "Boğa"
    case gemini = "İkizler"
    case cancer = "Yengeç"
    case leo = "Aslan"
    case virgo = "Başak"
    case libra = "Terazi"
    case scorpio = "Akrep"
    case sagittarius = "Yay"
    case capricorn = "Oğlak"
    case aquarius = "Kova"
    case pisces = "Balık"

    var glyph: String {
        switch self {
        case .aries: "♈"
        case .taurus: "♉"
        case .gemini: "♊"
        case .cancer: "♋"
        case .leo: "♌"
        case .virgo: "♍"
        case .libra: "♎"
        case .scorpio: "♏"
        case .sagittarius: "♐"
        case .capricorn: "♑"
        case .aquarius: "♒"
        case .pisces: "♓"
        }
    }

    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: "fire"
        case .taurus, .virgo, .capricorn: "earth"
        case .gemini, .libra, .aquarius: "air"
        case .cancer, .scorpio, .pisces: "water"
        }
    }

    static func from(longitude: Double) -> WidgetZodiacSign {
        let normalized = ((longitude.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int(normalized / 30.0)
        return allCases[min(index, 11)]
    }

    /// Dogum tarihinden gunes burcunu hesapla
    static func from(birthDate: Date) -> WidgetZodiacSign {
        let cal = Calendar.current
        let month = cal.component(.month, from: birthDate)
        let day = cal.component(.day, from: birthDate)

        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        default: return .aries
        }
    }
}

// MARK: - Ay Fazı Hesaplama

enum WidgetMoonPhase: String {
    case newMoon, waxingCrescent, firstQuarter, waxingGibbous
    case fullMoon, waningGibbous, lastQuarter, waningCrescent

    var name: String {
        switch self {
        case .newMoon: "Yeni Ay"
        case .waxingCrescent: "Hilal (Büyüyen)"
        case .firstQuarter: "İlk Dördün"
        case .waxingGibbous: "Şişkin Ay (Büyüyen)"
        case .fullMoon: "Dolunay"
        case .waningGibbous: "Şişkin Ay (Küçülen)"
        case .lastQuarter: "Son Dördün"
        case .waningCrescent: "Hilal (Küçülen)"
        }
    }

    var sfSymbol: String {
        switch self {
        case .newMoon: "moonphase.new.moon"
        case .waxingCrescent: "moonphase.waxing.crescent"
        case .firstQuarter: "moonphase.first.quarter"
        case .waxingGibbous: "moonphase.waxing.gibbous"
        case .fullMoon: "moonphase.full.moon"
        case .waningGibbous: "moonphase.waning.gibbous"
        case .lastQuarter: "moonphase.last.quarter"
        case .waningCrescent: "moonphase.waning.crescent"
        }
    }

    var shortTip: String {
        switch self {
        case .newMoon: "Niyet belirleme zamanı"
        case .waxingCrescent: "Plan yapma zamanı"
        case .firstQuarter: "Eylem zamanı"
        case .waxingGibbous: "Sabır zamanı"
        case .fullMoon: "Kutlama zamanı"
        case .waningGibbous: "Şükran zamanı"
        case .lastQuarter: "Arınma zamanı"
        case .waningCrescent: "Dinlenme zamanı"
        }
    }
}

struct WidgetMoonInfo {
    let phase: WidgetMoonPhase
    let illumination: Double
    let moonSign: WidgetZodiacSign
}

enum WidgetMoonCalculator {
    private static let knownNewMoon: TimeInterval = 947182440
    private static let synodicMonth: TimeInterval = 29.53058770576 * 86400

    static func current(for date: Date = .now) -> WidgetMoonInfo {
        let age = moonAge(for: date)
        return WidgetMoonInfo(
            phase: phase(from: age),
            illumination: (1 - cos(age / 29.53058770576 * 2 * .pi)) / 2,
            moonSign: moonSign(for: date)
        )
    }

    private static func moonAge(for date: Date) -> Double {
        let elapsed = date.timeIntervalSince1970 - knownNewMoon
        let cycles = elapsed / synodicMonth
        return (cycles - floor(cycles)) * 29.53058770576
    }

    private static func phase(from age: Double) -> WidgetMoonPhase {
        switch age {
        case 0..<1.85:      .newMoon
        case 1.85..<7.38:   .waxingCrescent
        case 7.38..<9.23:   .firstQuarter
        case 9.23..<14.77:  .waxingGibbous
        case 14.77..<16.61: .fullMoon
        case 16.61..<22.15: .waningGibbous
        case 22.15..<24.0:  .lastQuarter
        default:             .waningCrescent
        }
    }

    private static func moonSign(for date: Date) -> WidgetZodiacSign {
        let siderealMonth: TimeInterval = 27.321661 * 86400
        let elapsed = date.timeIntervalSince1970 - knownNewMoon
        let fraction = (elapsed / siderealMonth).truncatingRemainder(dividingBy: 1.0)
        let longitude = (280.0 + fraction * 360.0).truncatingRemainder(dividingBy: 360.0)
        return WidgetZodiacSign.from(longitude: longitude)
    }
}

// MARK: - Gezegen Saati Hesaplama

struct WidgetPlanetaryHour {
    let planet: String
    let planetSymbol: String
    let startTime: Date
    let endTime: Date
    let isDayHour: Bool

    var timeText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "HH:mm"
        return "\(f.string(from: startTime)) – \(f.string(from: endTime))"
    }

    var isActive: Bool {
        let now = Date.now
        return now >= startTime && now < endTime
    }
}

enum WidgetPlanetaryHourCalculator {
    private static let chaldeanOrder = [
        ("Satürn", "♄"), ("Jüpiter", "♃"), ("Mars", "♂"),
        ("Güneş", "☉"), ("Venüs", "♀"), ("Merkür", "☿"), ("Ay", "☽")
    ]

    private static let dayRulers: [Int: Int] = [
        1: 3, // Pazar → Güneş (index 3)
        2: 6, // Pazartesi → Ay (index 6)
        3: 2, // Salı → Mars
        4: 5, // Çarşamba → Merkür
        5: 1, // Perşembe → Jüpiter
        6: 4, // Cuma → Venüs
        7: 0, // Cumartesi → Satürn
    ]

    static func currentHour(date: Date = .now, latitude: Double, longitude: Double) -> WidgetPlanetaryHour? {
        // Bugünün saatlerini dene
        let hours = calculate(date: date, latitude: latitude, longitude: longitude)
        if let hour = hours.first(where: { $0.isActive }) {
            return hour
        }
        // Gece yarısından sonra, dünün gece saatlerini dene
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        let yesterdayHours = calculate(date: yesterday, latitude: latitude, longitude: longitude)
        return yesterdayHours.first(where: { $0.isActive })
    }

    static func calculate(date: Date, latitude: Double, longitude: Double) -> [WidgetPlanetaryHour] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 172
        let declination = 23.44 * sin(2 * .pi * Double(dayOfYear - 81) / 365.0)
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180

        let cosHA = -tan(latRad) * tan(decRad)
        let hourAngle: Double
        if cosHA < -1 { hourAngle = .pi }
        else if cosHA > 1 { hourAngle = 0 }
        else { hourAngle = acos(cosHA) }

        let dayLen = 2 * hourAngle * 12 / .pi
        let nightLen = 24 - dayLen

        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let sunrise = noon.addingTimeInterval((12.0 - dayLen / 2 - 12.0) * 3600)
        let sunset = noon.addingTimeInterval((12.0 + dayLen / 2 - 12.0) * 3600)

        let dayHourLen = dayLen * 3600 / 12.0
        let nightHourLen = nightLen * 3600 / 12.0

        let weekday = calendar.component(.weekday, from: date)
        let startIdx = dayRulers[weekday] ?? 3

        var hours: [WidgetPlanetaryHour] = []

        for i in 0..<12 {
            let pi = (startIdx + i) % 7
            hours.append(WidgetPlanetaryHour(
                planet: chaldeanOrder[pi].0,
                planetSymbol: chaldeanOrder[pi].1,
                startTime: sunrise.addingTimeInterval(Double(i) * dayHourLen),
                endTime: sunrise.addingTimeInterval(Double(i + 1) * dayHourLen),
                isDayHour: true
            ))
        }

        for i in 0..<12 {
            let pi = (startIdx + 12 + i) % 7
            hours.append(WidgetPlanetaryHour(
                planet: chaldeanOrder[pi].0,
                planetSymbol: chaldeanOrder[pi].1,
                startTime: sunset.addingTimeInterval(Double(i) * nightHourLen),
                endTime: sunset.addingTimeInterval(Double(i + 1) * nightHourLen),
                isDayHour: false
            ))
        }

        return hours
    }
}
