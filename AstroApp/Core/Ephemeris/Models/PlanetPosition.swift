import Foundation

struct PlanetPosition: Identifiable, Codable, Sendable {
    var id: Planet { planet }

    let planet: Planet
    let longitude: Double
    let latitude: Double
    let speed: Double

    var sign: ZodiacSign {
        ZodiacSign.from(longitude: longitude)
    }

    var degree: Double {
        longitude.truncatingRemainder(dividingBy: 30.0)
    }

    var house: Int

    var isRetrograde: Bool {
        speed < 0
    }
}
