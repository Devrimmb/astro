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

        // Gezegen + Ev + Burç üçlü kombinasyon yorumları (yalnızca eşleşme varsa)
        for position in chart.planets {
            if let entry = PlanetHouseSignInterpretation.interpretation(
                planet: position.planet,
                house: position.house,
                zodiacSign: position.sign
            ) {
                sections.append(InterpretationSection(
                    title: entry.title,
                    body: entry.description,
                    category: .planetInHouseSign
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

    /// Tek bir gezegenle ilgili tüm yorumları toplar:
    /// burç, ev, üçlü (ev+burç) kombinasyonu ve o gezegeni içeren açılar.
    /// Gezegen pozisyon kartındaki detay panelinde kullanılır.
    func interpretations(forPlanet planet: Planet, in chart: BirthChart) -> [InterpretationSection] {
        guard let pos = chart.planets.first(where: { $0.planet == planet }) else { return [] }
        var out: [InterpretationSection] = []

        if let i = planetInSign(planet, pos.sign) {
            out.append(InterpretationSection(title: i.title, body: i.detailed, category: .planetInSign))
        }
        if let i = planetInHouse(planet, pos.house) {
            out.append(InterpretationSection(title: i.title, body: i.detailed, category: .planetInHouse))
        }
        if let e = PlanetHouseSignInterpretation.interpretation(planet: planet, house: pos.house, zodiacSign: pos.sign) {
            out.append(InterpretationSection(title: e.title, body: e.description, category: .planetInHouseSign))
        }
        for aspect in chart.aspects {
            let involves: Bool = {
                if case .planet(let p) = aspect.point1, p == planet { return true }
                if case .planet(let p) = aspect.point2, p == planet { return true }
                return false
            }()
            if involves, let i = aspectInterpretation(aspect) {
                out.append(InterpretationSection(title: i.title, body: i.detailed, category: .aspect))
            }
        }
        return out
    }

    func planetInSign(_ planet: Planet, _ sign: ZodiacSign) -> Interpretation? {
        planetsInSigns[planet.identifier]?[sign.identifier]
    }

    func planetInHouse(_ planet: Planet, _ house: Int) -> Interpretation? {
        planetsInHouses[planet.identifier]?["house_\(house)"]
    }

    func aspectInterpretation(_ aspect: Aspect) -> Interpretation? {
        // ASC/MC için yorum yok — sadece gezegen çiftleri
        guard case .planet(let p1) = aspect.point1,
              case .planet(let p2) = aspect.point2 else { return nil }

        let key = "\(p1.identifier)_\(p2.identifier)"
        let aspectKey: String
        switch aspect.type {
        case .conjunction: aspectKey = "conjunction"
        case .sextile: aspectKey = "sextile"
        case .square: aspectKey = "square"
        case .trine: aspectKey = "trine"
        case .opposition: aspectKey = "opposition"
        // Minor aspect'ler için henüz JSON yorumu yok
        case .semiSextile: aspectKey = "semi_sextile"
        case .semiSquare: aspectKey = "semi_square"
        case .sesquiquadrate: aspectKey = "sesquiquadrate"
        case .quincunx: aspectKey = "quincunx"
        }
        return aspects[key]?[aspectKey]
    }
}
