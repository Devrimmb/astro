import Foundation

struct HouseSignEntry: Codable, Sendable, Identifiable {
    var id: String { "\(houseId)_\(sign)" }
    let houseId: Int
    let sign: String
    let name: String
    let description: String
}

/// Ev-burç yorum veritabanı — offline JSON'dan yüklenir.
enum HouseSignInterpretation {
    private static let entries: [HouseSignEntry] = {
        let data: [HouseSignEntry] = JSONLoader.load("house_signs")
        return data
    }()

    /// Belirli bir ev ve burç için yorum getir (JSON key: "Aries", "Taurus" vb.)
    static func interpretation(house: Int, sign: String) -> HouseSignEntry? {
        entries.first { $0.houseId == house && $0.sign.lowercased() == sign.lowercased() }
    }

    /// ZodiacSign enum'u ile yorum getir
    static func interpretation(house: Int, zodiacSign: ZodiacSign) -> HouseSignEntry? {
        interpretation(house: house, sign: zodiacSign.identifier)
    }

    /// Belirli bir ev için yorum metni getir
    static func description(house: Int, zodiacSign: ZodiacSign) -> String? {
        interpretation(house: house, zodiacSign: zodiacSign)?.description
    }

    /// Haritadaki tüm ev-burç eşleşmeleri için yorumları getir
    static func allInterpretations(for houses: [(houseNumber: Int, sign: ZodiacSign)]) -> [HouseSignEntry] {
        houses.compactMap { pair in
            interpretation(house: pair.houseNumber, zodiacSign: pair.sign)
        }
    }
}
