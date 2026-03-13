import Foundation

struct MockEphemerisCalculator: EphemerisCalculating, Sendable {
    func calculateBirthChart(
        date: Date, latitude: Double, longitude: Double, timeZone: TimeZone
    ) async -> BirthChart {
        let seed = abs(date.timeIntervalSince1970 + latitude * 1000 + longitude * 100)
        let seedInt = UInt64(seed.truncatingRemainder(dividingBy: 1_000_000))

        var rng = SeededRNG(seed: seedInt)

        let ascendantLongitude = Double.random(in: 0..<360, using: &rng)

        let planetLongitudes = generatePlanetLongitudes(seed: &rng)
        let houses = generateHouses(ascendant: ascendantLongitude)

        var planets: [PlanetPosition] = []
        for (index, planet) in Planet.allCases.enumerated() {
            let lon = planetLongitudes[index]
            let houseNumber = houseForLongitude(lon, houses: houses)
            let speed: Double
            switch planet {
            case .sun: speed = Double.random(in: 0.95...1.05, using: &rng)
            case .moon: speed = Double.random(in: 11.0...14.0, using: &rng)
            case .mercury: speed = Double.random(in: -1.5...2.0, using: &rng)
            case .venus: speed = Double.random(in: -0.6...1.3, using: &rng)
            case .mars: speed = Double.random(in: -0.4...0.8, using: &rng)
            case .jupiter: speed = Double.random(in: -0.1...0.25, using: &rng)
            case .saturn: speed = Double.random(in: -0.08...0.12, using: &rng)
            case .uranus: speed = Double.random(in: -0.04...0.06, using: &rng)
            case .neptune: speed = Double.random(in: -0.03...0.04, using: &rng)
            case .pluto: speed = Double.random(in: -0.02...0.03, using: &rng)
            case .northNode: speed = Double.random(in: -0.06...(-0.04), using: &rng)
            case .chiron: speed = Double.random(in: -0.02...0.06, using: &rng)
            case .lilith: speed = Double.random(in: 0.08...0.12, using: &rng)
            case .partOfFortune: speed = 0
            case .ceres: speed = Double.random(in: -0.1...0.3, using: &rng)
            case .pallas: speed = Double.random(in: -0.1...0.3, using: &rng)
            case .juno: speed = Double.random(in: -0.1...0.3, using: &rng)
            case .vesta: speed = Double.random(in: -0.1...0.3, using: &rng)
            }

            planets.append(PlanetPosition(
                planet: planet,
                longitude: lon,
                latitude: Double.random(in: -3.0...3.0, using: &rng),
                speed: speed,
                house: houseNumber
            ))
        }

        let aspects = AspectCalculator.calculate(planets: planets)

        return BirthChart(
            birthDate: date,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }

    private func generatePlanetLongitudes(seed: inout SeededRNG) -> [Double] {
        let sunLon = Double.random(in: 0..<360, using: &seed)
        return Planet.allCases.map { planet in
            switch planet {
            case .sun: return sunLon
            case .moon: return (sunLon + Double.random(in: 0..<360, using: &seed)).truncatingRemainder(dividingBy: 360)
            case .mercury: return (sunLon + Double.random(in: -28...28, using: &seed) + 360).truncatingRemainder(dividingBy: 360)
            case .venus: return (sunLon + Double.random(in: -47...47, using: &seed) + 360).truncatingRemainder(dividingBy: 360)
            case .mars: return Double.random(in: 0..<360, using: &seed)
            case .jupiter: return Double.random(in: 0..<360, using: &seed)
            case .saturn: return Double.random(in: 0..<360, using: &seed)
            case .uranus: return Double.random(in: 0..<360, using: &seed)
            case .neptune: return Double.random(in: 0..<360, using: &seed)
            case .pluto: return Double.random(in: 0..<360, using: &seed)
            case .northNode: return Double.random(in: 0..<360, using: &seed)
            case .chiron: return Double.random(in: 0..<360, using: &seed)
            case .lilith: return Double.random(in: 0..<360, using: &seed)
            case .partOfFortune: return Double.random(in: 0..<360, using: &seed)
            case .ceres: return Double.random(in: 0..<360, using: &seed)
            case .pallas: return Double.random(in: 0..<360, using: &seed)
            case .juno: return Double.random(in: 0..<360, using: &seed)
            case .vesta: return Double.random(in: 0..<360, using: &seed)
            }
        }
    }

    private func generateHouses(ascendant: Double) -> [House] {
        (1...12).map { number in
            let cusp = (ascendant + Double(number - 1) * 30.0).truncatingRemainder(dividingBy: 360)
            return House(id: number, cusp: cusp, planets: [])
        }
    }

    private func houseForLongitude(_ longitude: Double, houses: [House]) -> Int {
        for i in 0..<houses.count {
            let current = houses[i].cusp
            let next = i + 1 < houses.count ? houses[i + 1].cusp : houses[0].cusp + 360
            let lon = longitude < current ? longitude + 360 : longitude
            if lon >= current && lon < next {
                return houses[i].id
            }
        }
        return 1
    }
}

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
