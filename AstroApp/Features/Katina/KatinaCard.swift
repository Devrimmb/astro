import Foundation

struct KatinaCard: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let description: String

    var imageName: String { "katina_\(id)" }
}
