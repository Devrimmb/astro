import Foundation

@Observable
final class InterpretationEngine {
    private let planetsInSigns: [String: [String: Interpretation]]
    private let planetsInHouses: [String: [String: Interpretation]]
    private let aspects: [String: [String: Interpretation]]
    private let elements: [String: Interpretation]
    private let modalities: [String: Interpretation]

    init() {
        planetsInSigns = JSONLoader.load("planets_in_signs")
        planetsInHouses = JSONLoader.load("planets_in_houses")
        aspects = JSONLoader.load("aspects")
        elements = JSONLoader.load("elements")
        modalities = JSONLoader.load("modalities")
    }

    func interpret(chart: BirthChart) -> ChartInterpretation {
        var sections: [InterpretationSection] = []

        // Büyük Üçlü: Güneş, Ay, Yükselen
        for planet in [Planet.sun, .moon] {
            if let position = chart.planets.first(where: { $0.planet == planet }),
               let interp = planetInSign(planet, position.sign) {
                let category: InterpretationCategory = .bigThree
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: category
                ))
            }
        }

        if let ascSign = chart.ascendant {
            let key = "ascendant"
            if let signData = planetsInSigns[key],
               let interp = signData[ascSign.identifier] {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .bigThree
                ))
            }
        }

        // Gezegen-Burç yorumları
        for position in chart.planets {
            guard position.planet != .sun && position.planet != .moon else { continue }
            if let interp = planetInSign(position.planet, position.sign) {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .planetInSign
                ))
            }
        }

        // Gezegen-Ev yorumları
        for position in chart.planets {
            if let interp = planetInHouse(position.planet, position.house) {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .planetInHouse
                ))
            }
        }

        // Açı yorumları
        for aspect in chart.aspects {
            if let interp = aspectInterpretation(aspect) {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .aspect
                ))
            }
        }

        // Element dengesi
        if let dominant = chart.dominantElement {
            let key: String
            switch dominant {
            case .fire: key = "fire"
            case .earth: key = "earth"
            case .air: key = "air"
            case .water: key = "water"
            }
            if let interp = elements[key] {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .element
                ))
            }
        }

        // Modalite dengesi
        if let dominant = chart.dominantModality {
            let key: String
            switch dominant {
            case .cardinal: key = "cardinal"
            case .fixed: key = "fixed"
            case .mutable: key = "mutable"
            }
            if let interp = modalities[key] {
                sections.append(InterpretationSection(
                    title: interp.title,
                    body: interp.detailed,
                    category: .modality
                ))
            }
        }

        return ChartInterpretation(sections: sections)
    }

    func planetInSign(_ planet: Planet, _ sign: ZodiacSign) -> Interpretation? {
        planetsInSigns[planet.identifier]?[sign.identifier]
    }

    func planetInHouse(_ planet: Planet, _ house: Int) -> Interpretation? {
        planetsInHouses[planet.identifier]?["house_\(house)"]
    }

    func aspectInterpretation(_ aspect: Aspect) -> Interpretation? {
        let key = "\(aspect.planet1.identifier)_\(aspect.planet2.identifier)"
        let aspectKey: String
        switch aspect.type {
        case .conjunction: aspectKey = "conjunction"
        case .sextile: aspectKey = "sextile"
        case .square: aspectKey = "square"
        case .trine: aspectKey = "trine"
        case .opposition: aspectKey = "opposition"
        }
        return aspects[key]?[aspectKey]
    }
}
