import Foundation

/// App Group uzerinden main app ile veri paylasimi (Widget tarafi)
enum WidgetSharedDefaults {
    static let suiteName = "group.com.duygubal.AstroApp"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var userSign: WidgetZodiacSign {
        guard let raw = shared.string(forKey: "widget_user_sign"),
              let sign = WidgetZodiacSign(rawValue: raw) else {
            return .aries
        }
        return sign
    }

    static var userName: String {
        shared.string(forKey: "widget_user_name") ?? ""
    }

    static var latitude: Double {
        let val = shared.double(forKey: "widget_user_latitude")
        return val == 0 ? 41.0082 : val
    }

    static var longitude: Double {
        let val = shared.double(forKey: "widget_user_longitude")
        return val == 0 ? 28.9784 : val
    }
}
