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

    private static let planetWeights: [Planet: Double] = [
        .sun: 3, .moon: 3,
        .mercury: 1.75, .venus: 1.75, .mars: 1.75,
        .jupiter: 1.5, .saturn: 1.5,
        .uranus: 1, .neptune: 1, .pluto: 1
    ]

    var elementBalance: [ZodiacSign.Element: Double] {
        var scores: [ZodiacSign.Element: Double] = [:]
        for position in planets {
            guard let weight = BirthChart.planetWeights[position.planet] else { continue }
            scores[position.sign.element, default: 0] += weight
        }
        // Yükselen burç: 3 puan
        if let ascCusp = houses.first(where: { $0.id == 1 })?.cusp {
            let ascSign = ZodiacSign.from(longitude: ascCusp)
            scores[ascSign.element, default: 0] += 3
        }
        return scores
    }

    var modalityBalance: [ZodiacSign.Modality: Int] {
        var counts: [ZodiacSign.Modality: Int] = [:]
        for position in planets {
            guard BirthChart.planetWeights[position.planet] != nil else { continue }
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
