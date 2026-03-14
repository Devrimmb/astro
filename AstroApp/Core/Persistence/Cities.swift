import Foundation

/// Geriye uyumluluk — artık WorldCityStore kullanılıyor.
enum Cities {
    static var list: [(name: String, lat: Double, lon: Double)] {
        WorldCityStore.cities(for: "TR").map { ($0.city, $0.lat, $0.lon) }
    }

    static func coordinates(for cityName: String) -> (lat: Double, lon: Double) {
        WorldCityStore.coordinates(for: cityName)
    }
}
