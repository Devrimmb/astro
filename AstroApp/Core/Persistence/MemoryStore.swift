import Foundation

/// Kişinin önemli bir günü (geçmiş ya da planlanan). O günün gökyüzü kişinin haritası
/// etrafında gösterilir.
struct LifeMemory: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var personID: UUID
    var title: String
    var emoji: String
    /// Cihaz saatiyle girilen tarih; saat bilinmiyorsa öğlen 12:00
    var date: Date
    var hasTime: Bool
    var note: String

    var isFuture: Bool { date > .now }
}

/// Anıları cihazda kalıcı tutar
@Observable
final class MemoryStore {
    private static let storageKey = "savedMemories"

    private(set) var memories: [LifeMemory] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([LifeMemory].self, from: data) {
            memories = decoded
        }
    }

    /// Kişinin anıları, tarihe göre artan
    func memories(for personID: UUID) -> [LifeMemory] {
        memories.filter { $0.personID == personID }.sorted { $0.date < $1.date }
    }

    func memory(id: UUID) -> LifeMemory? {
        memories.first { $0.id == id }
    }

    /// Yoksa ekler, varsa günceller
    func save(_ memory: LifeMemory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
        } else {
            memories.append(memory)
        }
        persist()
    }

    func remove(id: UUID) {
        memories.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }
}
