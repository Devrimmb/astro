import Foundation

struct RisingSignEntry: Codable, Sendable, Identifiable {
    var id: String { "\(risingKey)_\(sunKey)" }
    let risingKey: String
    let sunKey: String
    let name: String
    let risingElement: String
    let sunElement: String
    let description: String
}

/// Yükselen burç + güneş burcu yorum veritabanı
enum RisingSignInterpretation {
    private static let entries: [RisingSignEntry] = {
        let data: [RisingSignEntry] = JSONLoader.load("rising_signs")
        return data
    }()

    /// Yükselen burç ve güneş burcuna göre yorum getir
    static func interpretation(rising: ZodiacSign, sun: ZodiacSign) -> RisingSignEntry? {
        let risingId = rising.identifier.capitalizingFirst
        let sunId = sun.identifier.capitalizingFirst
        return entries.first { $0.risingKey == risingId && $0.sunKey == sunId }
    }
}

private extension String {
    var capitalizingFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
