import Foundation

enum Cities {
    static let list: [(name: String, lat: Double, lon: Double)] = [
        ("İstanbul", 41.0082, 28.9784),
        ("Ankara", 39.9334, 32.8597),
        ("İzmir", 38.4192, 27.1287),
        ("Antalya", 36.8969, 30.7133),
        ("Bursa", 40.1885, 29.0610),
        ("Adana", 37.0000, 35.3213),
        ("Trabzon", 41.0027, 39.7168),
        ("Diyarbakır", 37.9144, 40.2306),
        ("Konya", 37.8746, 32.4932),
        ("Samsun", 41.2867, 36.3300),
    ]

    static func coordinates(for cityName: String) -> (lat: Double, lon: Double) {
        if let city = list.first(where: { $0.name == cityName }) {
            return (city.lat, city.lon)
        }
        return (41.0082, 28.9784) // İstanbul fallback
    }
}
