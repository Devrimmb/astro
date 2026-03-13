import Foundation

/// Gezegen saati
struct PlanetaryHour: Identifiable, Sendable {
    let id = UUID()
    let hourNumber: Int
    let planet: Planet
    let startTime: Date
    let endTime: Date
    let isDayHour: Bool

    var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    /// Su an bu saat aktif mi?
    var isActive: Bool {
        let now = Date.now
        return now >= startTime && now <= endTime
    }

    /// Gezegen saatinin anlami
    var meaning: String {
        switch planet {
        case .sun: "Liderlik, yaraticilik, basari"
        case .moon: "Duygular, sezgi, aile"
        case .mars: "Enerji, aksiyon, cesaret"
        case .mercury: "Iletisim, ticaret, ogrenme"
        case .jupiter: "Sans, bolluk, genisleme"
        case .venus: "Ask, guzellik, harmoni"
        case .saturn: "Disiplin, sorumluluk, yapi"
        default: ""
        }
    }
}

/// Gunun gezegen saatleri
struct DailyPlanetaryHours: Sendable {
    let date: Date
    let hours: [PlanetaryHour]

    var currentHour: PlanetaryHour? {
        hours.first(where: { $0.isActive })
    }
}
