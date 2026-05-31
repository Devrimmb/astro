import Foundation

/// App Group uzerinden widget ile veri paylasimi
enum SharedDefaults {
    static let suiteName = "group.com.duygubal.AstroApp"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Keys

    struct PlanetSnapshot: Codable {
        let name: String
        let symbol: String
        let signName: String
        let signGlyph: String
        let isRetrograde: Bool
    }

    private enum Keys {
        static let userSign = "widget_user_sign"
        static let userName = "widget_user_name"
        static let userLatitude = "widget_user_latitude"
        static let userLongitude = "widget_user_longitude"
        static let userBirthDate = "widget_user_birth_date"
        static let todayPlanets = "widget_today_planets"
    }

    // MARK: - Write (Main App)

    static func saveTodayPlanets(_ planets: [PlanetSnapshot]) {
        if let data = try? JSONEncoder().encode(planets) {
            shared.set(data, forKey: Keys.todayPlanets)
        }
    }

    static func saveTodayPlanets(from positions: [PlanetPosition]) {
        let snapshots = positions
            .filter { $0.planet.widgetSymbol != "·" }
            .map { pos in
                PlanetSnapshot(
                    name: pos.planet.name,
                    symbol: pos.planet.widgetSymbol,
                    signName: pos.sign.name,
                    signGlyph: pos.sign.glyph,
                    isRetrograde: pos.isRetrograde
                )
            }
        saveTodayPlanets(snapshots)
    }

    // MARK: - Read (Widget)

    static var todayPlanetsData: Data? {
        shared.data(forKey: Keys.todayPlanets)
    }

    static func saveForWidget(signRawValue: String, name: String, latitude: Double, longitude: Double, birthDate: Date? = nil) {
        let defaults = shared
        defaults.set(signRawValue, forKey: Keys.userSign)
        defaults.set(name, forKey: Keys.userName)
        defaults.set(latitude, forKey: Keys.userLatitude)
        defaults.set(longitude, forKey: Keys.userLongitude)
        if let birthDate {
            defaults.set(birthDate.timeIntervalSince1970, forKey: Keys.userBirthDate)
        }
    }

    // MARK: - Read (Widget)

    static var userSignRawValue: String? {
        shared.string(forKey: Keys.userSign)
    }

    static var userName: String? {
        shared.string(forKey: Keys.userName)
    }

    static var userLatitude: Double {
        let val = shared.double(forKey: Keys.userLatitude)
        return val == 0 ? 41.0082 : val // Istanbul default
    }

    static var userLongitude: Double {
        let val = shared.double(forKey: Keys.userLongitude)
        return val == 0 ? 28.9784 : val
    }

    static var userBirthDate: Date? {
        let val = shared.double(forKey: Keys.userBirthDate)
        return val == 0 ? nil : Date(timeIntervalSince1970: val)
    }
}
