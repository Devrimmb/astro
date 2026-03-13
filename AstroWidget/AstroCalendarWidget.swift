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

// MARK: - Basit Retrograde Tespiti

enum WidgetRetrogradeDetector {
    // 2026 retrograde yaklaşık tarihleri (dayOfYear)
    // Merkür: ~74-96, ~166-190, ~260-282
    // Venüs: ~60-102
    // Mars: yok 2026'da
    static func activeRetrogrades(year: Int, dayOfYear: Int) -> [String] {
        var result: [String] = []
        if year == 2026 {
            if (74...96).contains(dayOfYear) || (166...190).contains(dayOfYear) || (260...282).contains(dayOfYear) {
                result.append("Merkür")
            }
            if (60...102).contains(dayOfYear) {
                result.append("Venüs")
            }
        }
        // Genel fallback: seed-based
        if year != 2026 {
            let seed = (dayOfYear * 7 + year * 13) % 365
            if seed % 88 < 21 { result.append("Merkür") }
        }
        return result
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
