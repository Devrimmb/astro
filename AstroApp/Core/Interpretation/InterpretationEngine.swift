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

    func aspectInterpretation(_ aspect: Aspect) -> Interpretation? {
        guard let point1 = interpretationIdentifier(for: aspect.point1),
              let point2 = interpretationIdentifier(for: aspect.point2) else { return nil }

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

        let directKey = "\(point1)_\(point2)"
        if let interpretation = aspects[directKey]?[aspectKey] {
            return interpretation
        }

        let reverseKey = "\(point2)_\(point1)"
        return aspects[reverseKey]?[aspectKey]
    }

    private func interpretationIdentifier(for point: ChartPoint) -> String? {
        switch point {
        case .planet(let planet):
            return planet.identifier
        case .midheaven:
            return "mc"
        case .ascendant:
            return "asc"
        }
    }
}
