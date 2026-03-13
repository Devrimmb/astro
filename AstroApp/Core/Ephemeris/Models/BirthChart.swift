import Foundation

struct BirthChart: Codable, Sendable {
    let birthDate: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    var planets: [PlanetPosition]
    var houses: [House]
    var aspects: [Aspect]

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var sunSign: ZodiacSign? {
        planets.first(where: { $0.planet == .sun })?.sign
    }

    var moonSign: ZodiacSign? {
        planets.first(where: { $0.planet == .moon })?.sign
    }

    var ascendant: ZodiacSign? {
        houses.first(where: { $0.id == 1 })?.sign
    }

    var elementBalance: [ZodiacSign.Element: Int] {
        var counts: [ZodiacSign.Element: Int] = [:]
        for position in planets {
            counts[position.sign.element, default: 0] += 1
        }
        return counts
    }

    var modalityBalance: [ZodiacSign.Modality: Int] {
        var counts: [ZodiacSign.Modality: Int] = [:]
        for position in planets {
            counts[position.sign.modality, default: 0] += 1
        }
        return counts
    }

    var dominantElement: ZodiacSign.Element? {
        elementBalance.max(by: { $0.value < $1.value })?.key
    }

    var dominantModality: ZodiacSign.Modality? {
        modalityBalance.max(by: { $0.value < $1.value })?.key
    }
}
