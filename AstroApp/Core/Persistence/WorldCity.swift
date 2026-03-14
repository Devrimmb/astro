import Foundation

struct WorldCity: Codable, Sendable, Identifiable {
    var id: String { "\(countryCode)_\(city)" }
    let country: String
    let countryCode: String
    let city: String
    let lat: Double
    let lon: Double
    let tz: String
}

/// Dünya şehirleri veri yöneticisi — offline JSON'dan yüklenir.
enum WorldCityStore {
    private static var _all: [WorldCity] = {
        let cities: [WorldCity] = JSONLoader.load("world_cities")
        return cities
    }()

    /// Tüm şehirler
    static var all: [WorldCity] { _all }

    /// Benzersiz ülke listesi (Türkçe sıralı, Türkiye en üstte)
    static var countries: [(name: String, code: String)] = {
        var seen = Set<String>()
        var result: [(name: String, code: String)] = []
        for city in _all {
            if seen.insert(city.countryCode).inserted {
                result.append((city.country, city.countryCode))
            }
        }
        // Türkiye'yi en üste al, kalanı alfabetik sırala
        let turkey = result.filter { $0.code == "TR" }
        let rest = result.filter { $0.code != "TR" }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        return turkey + rest
    }()

    /// Belirli bir ülkenin şehirleri (alfabetik sıralı)
    static func cities(for countryCode: String) -> [WorldCity] {
        _all.filter { $0.countryCode == countryCode }
            .sorted { $0.city.localizedCompare($1.city) == .orderedAscending }
    }

    /// Şehir adı ve ülke koduna göre koordinat bul
    static func coordinates(for cityName: String, countryCode: String) -> (lat: Double, lon: Double, tz: String) {
        if let city = _all.first(where: { $0.city == cityName && $0.countryCode == countryCode }) {
            return (city.lat, city.lon, city.tz)
        }
        // Sadece şehir adıyla ara (geriye uyumluluk)
        if let city = _all.first(where: { $0.city == cityName }) {
            return (city.lat, city.lon, city.tz)
        }
        return (41.0082, 28.9784, "Europe/Istanbul") // İstanbul fallback
    }

    /// Ülke kodu olmadan şehir adıyla ara (eski Cities.coordinates uyumluluğu)
    static func coordinates(for cityName: String) -> (lat: Double, lon: Double) {
        let result = coordinates(for: cityName, countryCode: "TR")
        return (result.lat, result.lon)
    }
}
