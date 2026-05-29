import Foundation

@Observable
final class InterpretationEngine {
    private let aspects: [String: [String: Interpretation]]
    private let elements: [String: Interpretation]
    private let modalities: [String: Interpretation]

    init() {
        aspects = JSONLoader.load("aspects")
        elements = JSONLoader.load("elements")
        modalities = JSONLoader.load("modalities")
    }

    func interpret(chart: BirthChart) -> ChartInterpretation {
        var sections: [InterpretationSection] = []

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

    /// Tek bir gezegenle ilgili yorumları toplar: ev + burç üçlü kombinasyonu
    /// (varsa) ve o gezegeni içeren açılar. Gezegen pozisyon kartındaki detay
    /// panelinde kullanılır.
    func interpretations(forPlanet planet: Planet, in chart: BirthChart) -> [InterpretationSection] {
        guard let pos = chart.planets.first(where: { $0.planet == planet }) else { return [] }
        var out: [InterpretationSection] = []

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
