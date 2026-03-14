import Foundation

struct RuneCard: Identifiable, Codable, Sendable {
    let id: Int
    let name: String
    let symbol: String
    let description: String
}
