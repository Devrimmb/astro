import Foundation

struct LifeCycleEntry: Codable, Sendable, Identifiable {
    var id: String { key }
    let key: String
    let title: String
    let planet: String
    let aspect: String
    let typicalAges: String
    let summary: String
    let description: String
    /// Kaçıncı gerçekleşme olduğuna göre ek not ("1", "2", …)
    let occurrences: [String: String]?
}

/// Hayat döngüsü yorum veritabanı (`life_cycles.json`)
enum LifeCycleInterpretation {
    private static let entries: [String: LifeCycleEntry] = {
        let data: [LifeCycleEntry] = JSONLoader.load("life_cycles")
        return Dictionary(uniqueKeysWithValues: data.map { ($0.key, $0) })
    }()

    static func entry(for kind: LifeCycleKind) -> LifeCycleEntry? {
        entries[kind.rawValue]
    }
}
