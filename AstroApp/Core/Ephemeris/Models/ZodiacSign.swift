import Foundation

enum ZodiacSign: Int, CaseIterable, Codable, Sendable {
    case aries = 0, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    enum Element: CaseIterable, Codable, Sendable {
        case fire, earth, air, water

        var displayName: String {
            switch self {
            case .fire: LanguageManager.localized( "Ateş")
            case .earth: LanguageManager.localized( "Toprak")
            case .air: LanguageManager.localized( "Hava")
            case .water: LanguageManager.localized( "Su")
            }
        }
    }

    enum Modality: CaseIterable, Codable, Sendable {
        case cardinal, fixed, mutable

        var displayName: String {
            switch self {
            case .cardinal: LanguageManager.localized( "Öncü")
            case .fixed: LanguageManager.localized( "Sabit")
            case .mutable: LanguageManager.localized( "Değişken")
            }
        }
    }

    var name: String {
        switch self {
        case .aries: LanguageManager.localized( "Koç")
        case .taurus: LanguageManager.localized( "Boğa")
        case .gemini: LanguageManager.localized( "İkizler")
        case .cancer: LanguageManager.localized( "Yengeç")
        case .leo: LanguageManager.localized( "Aslan")
        case .virgo: LanguageManager.localized( "Başak")
        case .libra: LanguageManager.localized( "Terazi")
        case .scorpio: LanguageManager.localized( "Akrep")
        case .sagittarius: LanguageManager.localized( "Yay")
        case .capricorn: LanguageManager.localized( "Oğlak")
        case .aquarius: LanguageManager.localized( "Kova")
        case .pisces: LanguageManager.localized( "Balık")
        }
    }

    var glyph: String {
        switch self {
        case .aries: "♈︎"
        case .taurus: "♉︎"
        case .gemini: "♊︎"
        case .cancer: "♋︎"
        case .leo: "♌︎"
        case .virgo: "♍︎"
        case .libra: "♎︎"
        case .scorpio: "♏︎"
        case .sagittarius: "♐︎"
        case .capricorn: "♑︎"
        case .aquarius: "♒︎"
        case .pisces: "♓︎"
        }
    }

    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: .fire
        case .taurus, .virgo, .capricorn: .earth
        case .gemini, .libra, .aquarius: .air
        case .cancer, .scorpio, .pisces: .water
        }
    }

    var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: .cardinal
        case .taurus, .leo, .scorpio, .aquarius: .fixed
        case .gemini, .virgo, .sagittarius, .pisces: .mutable
        }
    }

    var ruler: Planet {
        switch self {
        case .aries: .mars
        case .taurus: .venus
        case .gemini: .mercury
        case .cancer: .moon
        case .leo: .sun
        case .virgo: .mercury
        case .libra: .venus
        case .scorpio: .pluto
        case .sagittarius: .jupiter
        case .capricorn: .saturn
        case .aquarius: .uranus
        case .pisces: .neptune
        }
    }

    var identifier: String {
        switch self {
        case .aries: "aries"
        case .taurus: "taurus"
        case .gemini: "gemini"
        case .cancer: "cancer"
        case .leo: "leo"
        case .virgo: "virgo"
        case .libra: "libra"
        case .scorpio: "scorpio"
        case .sagittarius: "sagittarius"
        case .capricorn: "capricorn"
        case .aquarius: "aquarius"
        case .pisces: "pisces"
        }
    }

    static func from(longitude: Double) -> ZodiacSign {
        let index = Int(longitude / 30.0) % 12
        return ZodiacSign(rawValue: index)!
    }

    /// Dogum tarihinden gunes burcunu hesapla
    static func from(birthDate: Date) -> ZodiacSign {
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
