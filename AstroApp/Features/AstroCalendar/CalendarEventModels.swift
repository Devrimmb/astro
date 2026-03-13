import Foundation

// MARK: - Calendar Event Types

enum CalendarEventType: String, CaseIterable, Sendable, Hashable {
    case moonPhase = "Ay Fazı"
    case eclipse = "Tutulma"
    case retrograde = "Retrograde"
    case voidOfCourse = "Ay Boşlukta"
    case planetaryHour = "Gezegen Saati"

    var icon: String {
        switch self {
        case .moonPhase: "moon.stars"
        case .eclipse: "circle.lefthalf.striped.horizontal"
        case .retrograde: "arrow.backward.circle"
        case .voidOfCourse: "moon.haze"
        case .planetaryHour: "clock.fill"
        }
    }
}

// MARK: - Calendar Event

struct CalendarEvent: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let type: CalendarEventType
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Day Summary

struct CalendarDaySummary: Identifiable, Sendable {
    let id: String // "yyyy-MM-dd"
    let date: Date
    var events: [CalendarEvent]
    var moonPhase: MoonPhaseInfo?
    var dailyTip: String?

    var eventTypes: [CalendarEventType] {
        Array(Set(events.map(\.type)).sorted(by: { $0.rawValue < $1.rawValue })).prefix(4).map { $0 }
    }
}
