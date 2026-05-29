import Foundation

struct Interpretation: Codable, Sendable {
    let title: String
    let short: String
    let detailed: String
    let strengths: [String]?
    let challenges: [String]?
    let advice: String?
}

enum InterpretationCategory: Sendable {
    case bigThree
    case planetInHouseSign
    case houseInSign
    case aspect
    case element
    case modality
}

struct InterpretationSection: Identifiable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let category: InterpretationCategory

    init(title: String, body: String, category: InterpretationCategory) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.category = category
    }
}

struct ChartInterpretation: Sendable {
    let sections: [InterpretationSection]
}
