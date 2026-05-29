import Foundation

/// Gezegen + ev + burç üçlü kombinasyon yorumu (ör. "Güneş 2. Evde Koç Burcunda").
/// Word dosyalarından `tools/extract_planet_docs.py` ile üretilen
/// `planet_house_sign.json` dosyasından yüklenir. Veri kısmidir; yalnızca
/// eşleşme bulunan kombinasyonlar için yorum döner.
struct PlanetHouseSignEntry: Codable, Sendable, Identifiable {
    var id: String { "\(planet)_\(houseId)_\(sign)" }
    let planet: String
    let planetName: String
    let icon: String?
    let houseId: Int
    let sign: String
    let signName: String
    let title: String
    let description: String
}

enum PlanetHouseSignInterpretation {
    private static let entries: [PlanetHouseSignEntry] = {
        let data: [PlanetHouseSignEntry] = JSONLoader.load("planet_house_sign")
        return data
    }()

    /// String tanımlayıcılarla yorum getir (case-insensitive burç eşleşmesi).
    static func interpretation(planet: String, house: Int, sign: String) -> PlanetHouseSignEntry? {
        entries.first {
            $0.planet == planet
                && $0.houseId == house
                && $0.sign.lowercased() == sign.lowercased()
        }
    }

    /// Enum tipleriyle yorum getir.
    static func interpretation(planet: Planet, house: Int, zodiacSign: ZodiacSign) -> PlanetHouseSignEntry? {
        interpretation(planet: planet.identifier, house: house, sign: zodiacSign.identifier)
    }
}
