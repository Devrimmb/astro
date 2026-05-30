import WidgetKit
import SwiftUI

// MARK: - Entry

struct AstroCalendarEntry: TimelineEntry {
    let date: Date
    let moon: WidgetMoonInfo
    let tip: String
    let events: [WidgetCalendarEvent]
}

struct WidgetCalendarEvent: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

// MARK: - Provider

struct AstroCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> AstroCalendarEntry {
        makeEntry(for: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (AstroCalendarEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AstroCalendarEntry>) -> Void) {
        let entry = makeEntry(for: .now)
        let tomorrow = Calendar.current.startOfDay(for: Date.now.addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }

    private func makeEntry(for date: Date) -> AstroCalendarEntry {
        let moon = WidgetMoonCalculator.current(for: date)
        var events: [WidgetCalendarEvent] = []

        // Onemli ay fazlari
        let significantPhases: [WidgetMoonPhase] = [.newMoon, .fullMoon, .firstQuarter, .lastQuarter]
        if significantPhases.contains(moon.phase) {
            events.append(WidgetCalendarEvent(
                icon: moon.phase.sfSymbol,
                title: moon.phase.name,
                color: .yellow
            ))
        }

        // Retrograde tespiti (basit seed-based)
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let retrogrades = WidgetRetrogradeDetector.activeRetrogrades(year: year, dayOfYear: day)
        for retro in retrogrades {
            events.append(WidgetCalendarEvent(
                icon: "arrow.backward.circle",
                title: "\(retro) Retrograde",
                color: .red
            ))
        }

        let tip = widgetTip(moon: moon, retrogrades: retrogrades)

        return AstroCalendarEntry(date: date, moon: moon, tip: tip, events: events)
    }

    private func widgetTip(moon: WidgetMoonInfo, retrogrades: [String]) -> String {
        if retrogrades.contains("Merkür") {
            return "Merkür retrograde — iletişimde dikkatli olun."
        }
        return moon.phase.shortTip
    }
}

// MARK: - Retrograde Tespiti

enum WidgetRetrogradeDetector {
    private struct Period {
        let planet: String
        let start: Date
        let end: Date
    }

    private static func d(_ y: Int, _ m: Int, _ day: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = day
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c) ?? .distantPast
    }

    // SwissEphemeris ile hesaplanan gerçek 2025-2027 retrograd dönemleri
    private static let periods: [Period] = [
        // Merkür 2025
        Period(planet: "Merkür",  start: d(2025,3,15),  end: d(2025,4,7)),
        Period(planet: "Merkür",  start: d(2025,7,18),  end: d(2025,8,11)),
        Period(planet: "Merkür",  start: d(2025,11,9),  end: d(2025,12,1)),
        // Merkür 2026
        Period(planet: "Merkür",  start: d(2026,3,5),   end: d(2026,3,27)),
        Period(planet: "Merkür",  start: d(2026,7,4),   end: d(2026,7,28)),
        Period(planet: "Merkür",  start: d(2026,10,28), end: d(2026,11,18)),
        // Venüs 2026
        Period(planet: "Venüs",   start: d(2026,3,1),   end: d(2026,4,12)),
        // Jüpiter 2025-2026
        Period(planet: "Jüpiter", start: d(2025,11,11), end: d(2026,3,11)),
        Period(planet: "Jüpiter", start: d(2026,9,16),  end: d(2027,1,19)),
        // Satürn 2026
        Period(planet: "Satürn",  start: d(2026,7,2),   end: d(2026,11,19)),
        // Uranüs 2025-2026
        Period(planet: "Uranüs",  start: d(2025,9,6),   end: d(2026,2,4)),
        Period(planet: "Uranüs",  start: d(2026,9,14),  end: d(2027,2,12)),
        // Neptün 2026
        Period(planet: "Neptün",  start: d(2026,7,4),   end: d(2026,12,6)),
        // Plüton 2026
        Period(planet: "Plüton",  start: d(2026,5,7),   end: d(2026,10,17)),
    ]

    static func activeRetrogrades(for date: Date = .now) -> [String] {
        periods.filter { date >= $0.start && date <= $0.end }.map { $0.planet }
    }

    // Geriye dönük uyumluluk (AstroCalendarWidget çağrıları için)
    static func activeRetrogrades(year: Int, dayOfYear: Int) -> [String] {
        activeRetrogrades(for: .now)
    }
}

// MARK: - Widget

struct AstroCalendarWidget: Widget {
    let kind = "AstroCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstroCalendarProvider()) { entry in
            AstroCalendarWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Astro Takvim")
        .description("Gunluk ay fazi, tavsiye ve olaylar")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct AstroCalendarWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AstroCalendarEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(.yellow.opacity(0.8))
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.blue.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.moon.phase.name)
                    .font(.caption.bold())
                    .foregroundStyle(.white)

                HStack(spacing: 3) {
                    Text(entry.moon.moonSign.glyph)
                        .font(.caption)
                    Text(entry.moon.moonSign.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text(entry.tip)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !entry.events.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.events.prefix(3)) { event in
                        Circle()
                            .fill(event.color)
                            .frame(width: 5, height: 5)
                    }
                    Spacer()
                }
            }
        }
        .padding(2)
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(spacing: 14) {
            // Sol: Ay fazı
            VStack(spacing: 6) {
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow.opacity(0.8))
                Text(entry.moon.phase.name)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                HStack(spacing: 3) {
                    Text(entry.moon.moonSign.glyph)
                        .font(.caption)
                    Text(entry.moon.moonSign.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 80)

            // Sag: Tavsiye + olaylar
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                    Text(entry.tip)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer()

                if entry.events.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 9))
                            .foregroundStyle(.green.opacity(0.7))
                        Text("Bugün önemli olay yok")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    ForEach(entry.events.prefix(3)) { event in
                        HStack(spacing: 4) {
                            Image(systemName: event.icon)
                                .font(.system(size: 9))
                                .foregroundStyle(event.color)
                            Text(event.title)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }

                HStack {
                    Spacer()
                    Text(dateText)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(2)
    }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: entry.date)
    }
}
