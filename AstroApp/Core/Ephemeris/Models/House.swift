import Foundation

struct House: Identifiable, Codable, Sendable {
    let id: Int
    let cusp: Double

    var sign: ZodiacSign {
        ZodiacSign.from(longitude: cusp)
    }

    var degree: Double {
        cusp.truncatingRemainder(dividingBy: 30.0)
    }

    var planets: [PlanetPosition]
}
