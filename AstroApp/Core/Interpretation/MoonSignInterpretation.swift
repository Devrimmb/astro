import Foundation

struct MoonSignEntry: Codable, Sendable, Identifiable {
    var id: String { "\(sign)_\(gender)" }
    let sign: String
    let name: String
    let element: String
    let gender: String
    let description: String
}

/// Ay burcu yorum veritabanı — cinsiyete göre farklı yorumlar.
enum MoonSignInterpretation {
    private static let entries: [MoonSignEntry] = {
        let data: [MoonSignEntry] = JSONLoader.load("moon_signs")
        return data
    }()

    /// Belirli bir ay burcu ve cinsiyet için yorum getir
    /// - gender: "women" veya "men"
    static func interpretation(sign: ZodiacSign, gender: String) -> MoonSignEntry? {
        entries.first { $0.sign.lowercased() == sign.identifier && $0.gender == gender }
    }

    /// Yorum metnini getir
    static func description(sign: ZodiacSign, gender: String) -> String? {
        interpretation(sign: sign, gender: gender)?.description
    }
}
