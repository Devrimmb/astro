import Foundation

enum ZodiacSign: Int, CaseIterable, Codable, Sendable {
    case aries = 0, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces

    enum Element: CaseIterable, Codable, Sendable {
        case fire, earth, air, water

        var displayName: String {
            switch self {
            case .fire: "Ateş"
            case .earth: "Toprak"
            case .air: "Hava"
            case .water: "Su"
            }
        }
    }

    enum Modality: CaseIterable, Codable, Sendable {
        case cardinal, fixed, mutable

        var displayName: String {
            switch self {
            case .cardinal: "Öncü"
            case .fixed: "Sabit"
            case .mutable: "Değişken"
            }
        }
    }

    var name: String {
        switch self {
        case .aries: "Koç"
        case .taurus: "Boğa"
        case .gemini: "İkizler"
        case .cancer: "Yengeç"
        case .leo: "Aslan"
        case .virgo: "Başak"
        case .libra: "Terazi"
        case .scorpio: "Akrep"
        case .sagittarius: "Yay"
        case .capricorn: "Oğlak"
        case .aquarius: "Kova"
        case .pisces: "Balık"
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
}
