import Foundation

/// Hesaplanmış bir doğum haritası okuması
struct SavedChartReading: Codable, Sendable, Identifiable {
    let id: UUID
    let personID: UUID
    let personName: String
    let birthData: BirthData
    let chart: BirthChart
    let calculatedAt: Date

    init(
        id: UUID = UUID(),
        personID: UUID,
        personName: String,
        birthData: BirthData,
        chart: BirthChart,
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.personID = personID
        self.personName = personName
        self.birthData = birthData
        self.chart = chart
        self.calculatedAt = calculatedAt
    }
}

/// Geçmiş harita okumalarını kalıcı olarak saklar.
/// Aynı kişi için tekrar ödeme yapılmasını engeller.
@Observable
final class ChartReadingStore {
    private static let storageKey = "savedChartReadings"

    var readings: [SavedChartReading] = []

    init() {
        loadReadings()
    }

    /// Kişi ID'sine göre kayıtlı okuma bul
    func reading(forPersonID personID: UUID) -> SavedChartReading? {
        readings.first(where: { $0.personID == personID })
    }

    /// Yeni okuma kaydet (varsa güncelle)
    func saveReading(_ reading: SavedChartReading) {
        if let index = readings.firstIndex(where: { $0.personID == reading.personID }) {
            readings[index] = reading
        } else {
            readings.append(reading)
        }
        persistReadings()
    }

    /// Okuma sil
    func removeReading(forPersonID personID: UUID) {
        readings.removeAll(where: { $0.personID == personID })
        persistReadings()
    }

    /// Tüm okumaları temizle
    func clearAll() {
        readings.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    // MARK: - Persistence

    private func loadReadings() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([SavedChartReading].self, from: data) else {
            return
        }
        readings = decoded
    }

    private func persistReadings() {
        if let encoded = try? JSONEncoder().encode(readings) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }
}
