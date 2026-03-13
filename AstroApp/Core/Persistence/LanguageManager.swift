import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case turkish = "tr"
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: String(localized: "Sistem Dili")
        case .turkish: "Türkçe"
        case .english: "English"
        case .german: "Deutsch"
        }
    }

    var icon: String {
        switch self {
        case .system: "gear"
        case .turkish: "t.circle"
        case .english: "e.circle"
        case .german: "d.circle"
        }
    }

    /// Aktif locale. Sistem seçiliyse nil döner (SwiftUI default'u kullanır).
    var locale: Locale? {
        switch self {
        case .system: nil
        case .turkish: Locale(identifier: "tr")
        case .english: Locale(identifier: "en")
        case .german: Locale(identifier: "de")
        }
    }
}

@Observable
class LanguageManager {
    static let shared = LanguageManager()

    var selected: AppLanguage {
        didSet {
            UserDefaults.standard.set(selected.rawValue, forKey: "app_language")
        }
    }

    var activeLocale: Locale? {
        selected.locale
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "system"
        self.selected = AppLanguage(rawValue: saved) ?? .system
    }
}
