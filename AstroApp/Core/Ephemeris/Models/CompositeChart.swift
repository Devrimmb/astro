import Foundation

/// Composite harita — iki haritanin orta noktalari
struct CompositeChart: Sendable {
    let planets: [PlanetPosition]
    let houses: [House]
    let aspects: [Aspect]

    var sunSign: ZodiacSign? {
        planets.first(where: { $0.planet == .sun })?.sign
    }

    var moonSign: ZodiacSign? {
        planets.first(where: { $0.planet == .moon })?.sign
    }

    var ascendant: ZodiacSign? {
        houses.first(where: { $0.id == 1 })?.sign
    }

    /// ChartWheelView ile kullanmak icin BirthChart'a donustur
    var asBirthChart: BirthChart {
        BirthChart(
            birthDate: .now,
            latitude: 0,
            longitude: 0,
            timeZoneIdentifier: TimeZone.current.identifier,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }
}
