import Foundation

struct BirthData: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    let name: String
    let birthDate: Date
    let cityName: String
    let latitude: Double
    let longitude: Double
    let isOwner: Bool // true = kullanicinin kendi haritasi

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        cityName: String,
        latitude: Double,
        longitude: Double,
        isOwner: Bool = false
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.cityName = cityName
        self.latitude = latitude
        self.longitude = longitude
        self.isOwner = isOwner
    }
}

@Observable
final class BirthDataStore {
    private static let legacyKey = "savedBirthData"
    private static let peopleKey = "savedPeople"
    private static let activeIDKey = "activePeopleID"

    /// Tum kayitli kisiler
    var people: [BirthData] = [] {
        didSet { persistPeople() }
    }

    /// Aktif (secili) kisinin ID'si
    var activePersonID: UUID? {
        didSet {
            UserDefaults.standard.set(activePersonID?.uuidString, forKey: Self.activeIDKey)
        }
    }

    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    // MARK: - Geriye Uyumluluk

    /// Eski tek-kisi verisi (geriye uyumluluk)
    var savedData: BirthData? {
        activePerson
    }

    /// Aktif kisi
    var activePerson: BirthData? {
        if let id = activePersonID {
            return people.first(where: { $0.id == id })
        }
        // Fallback: owner olan kisiyi veya ilk kisiyi dondur
        return people.first(where: { $0.isOwner }) ?? people.first
    }

    /// Owner olan kisi (kullanicinin kendi haritasi)
    var ownerPerson: BirthData? {
        people.first(where: { $0.isOwner })
    }

    // MARK: - Init

    init() {
        // Yeni format'i yukle
        if let data = UserDefaults.standard.data(forKey: Self.peopleKey),
           let decoded = try? JSONDecoder().decode([BirthData].self, from: data) {
            self.people = decoded
        }

        // Aktif kisi ID'sini yukle
        if let idString = UserDefaults.standard.string(forKey: Self.activeIDKey),
           let id = UUID(uuidString: idString) {
            self.activePersonID = id
        }

        // Eski format'tan migration
        if people.isEmpty, let legacyData = loadLegacy() {
            let person = BirthData(
                name: legacyData.name,
                birthDate: legacyData.birthDate,
                cityName: legacyData.cityName,
                latitude: legacyData.latitude,
                longitude: legacyData.longitude,
                isOwner: true
            )
            people = [person]
            activePersonID = person.id
        }
    }

    // MARK: - CRUD

    /// Yeni kisi ekle
    func addPerson(_ data: BirthData) {
        people.append(data)
        // Ilk kisi ise aktif yap
        if people.count == 1 || data.isOwner {
            activePersonID = data.id
        }
    }

    /// Kisi guncelle
    func updatePerson(_ data: BirthData) {
        if let index = people.firstIndex(where: { $0.id == data.id }) {
            people[index] = data
        }
    }

    /// Kisi sil
    func removePerson(_ id: UUID) {
        people.removeAll(where: { $0.id == id })
        if activePersonID == id {
            activePersonID = people.first?.id
        }
    }

    /// Aktif kisiyi degistir
    func setActive(_ id: UUID) {
        activePersonID = id
    }

    /// Eski save metodu (geriye uyumluluk — onboarding'den cagriliyor)
    func save(_ data: BirthData) {
        // Owner olarak kaydet
        let ownerData = BirthData(
            id: ownerPerson?.id ?? data.id,
            name: data.name,
            birthDate: data.birthDate,
            cityName: data.cityName,
            latitude: data.latitude,
            longitude: data.longitude,
            isOwner: true
        )

        if let existing = ownerPerson {
            updatePerson(BirthData(
                id: existing.id,
                name: ownerData.name,
                birthDate: ownerData.birthDate,
                cityName: ownerData.cityName,
                latitude: ownerData.latitude,
                longitude: ownerData.longitude,
                isOwner: true
            ))
        } else {
            addPerson(ownerData)
        }

        activePersonID = ownerData.id
        hasCompletedOnboarding = true
    }

    func clear() {
        people.removeAll()
        activePersonID = nil
        UserDefaults.standard.removeObject(forKey: Self.peopleKey)
        UserDefaults.standard.removeObject(forKey: Self.activeIDKey)
    }

    // MARK: - Persistence

    private func persistPeople() {
        if let encoded = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(encoded, forKey: Self.peopleKey)
        }
    }

    /// Eski format'i oku (migration icin)
    private func loadLegacy() -> BirthData? {
        // Eski format: farkli struct olabilir, ama ayni field'lara sahip
        guard let data = UserDefaults.standard.data(forKey: Self.legacyKey),
              let decoded = try? JSONDecoder().decode(LegacyBirthData.self, from: data) else {
            return nil
        }
        return BirthData(
            name: decoded.name,
            birthDate: decoded.birthDate,
            cityName: decoded.cityName,
            latitude: decoded.latitude,
            longitude: decoded.longitude,
            isOwner: true
        )
    }
}

/// Eski format (migration icin)
private struct LegacyBirthData: Codable {
    let name: String
    let birthDate: Date
    let cityName: String
    let latitude: Double
    let longitude: Double
}
