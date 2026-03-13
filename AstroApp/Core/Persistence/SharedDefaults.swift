import Foundation

/// App Group uzerinden widget ile veri paylasimi
enum SharedDefaults {
    static let suiteName = "group.com.duygubal.AstroApp"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Keys

    private enum Keys {
        static let userSign = "widget_user_sign"
        static let userName = "widget_user_name"
        static let userLatitude = "widget_user_latitude"
        static let userLongitude = "widget_user_longitude"
    }

    // MARK: - Write (Main App)

    static func saveForWidget(signRawValue: String, name: String, latitude: Double, longitude: Double) {
        let defaults = shared
        defaults.set(signRawValue, forKey: Keys.userSign)
        defaults.set(name, forKey: Keys.userName)
        defaults.set(latitude, forKey: Keys.userLatitude)
        defaults.set(longitude, forKey: Keys.userLongitude)
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
}
