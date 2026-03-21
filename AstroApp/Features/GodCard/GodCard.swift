import Foundation

struct GodCard: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let description: String

    var imageName: String { "god_\(id)" }
}
