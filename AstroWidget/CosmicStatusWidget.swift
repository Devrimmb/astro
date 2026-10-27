import WidgetKit
import SwiftUI

// MARK: - Entry

struct CosmicStatusEntry: TimelineEntry {
    let date: Date
    let moon: WidgetMoonInfo
    let retrogrades: [String]
    let planetaryHour: WidgetPlanetaryHour?
    let planets: [WidgetPlanetInfo]
}

// MARK: - Provider

struct CosmicStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> CosmicStatusEntry {
        makeEntry(for: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (CosmicStatusEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CosmicStatusEntry>) -> Void) {
        var entries: [CosmicStatusEntry] = []
        let now = Date.now
        for hourOffset in 0..<12 {
            let date = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            entries.append(makeEntry(for: date))
        }
        let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }

    private func makeEntry(for date: Date) -> CosmicStatusEntry {
        let lat = WidgetSharedDefaults.latitude
        let lon = WidgetSharedDefaults.longitude
        return CosmicStatusEntry(
            date: date,
            moon: WidgetMoonCalculator.current(for: date),
            retrogrades: WidgetRetrogradeDetector.activeRetrogrades(for: date),
            planetaryHour: WidgetPlanetaryHourCalculator.currentHour(date: date, latitude: lat, longitude: lon),
            planets: WidgetPlanetStore.load()
        )
    }
}

// MARK: - Widget

struct CosmicStatusWidget: Widget {
    let kind = "CosmicStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CosmicStatusProvider()) { entry in
            CosmicStatusWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetSkyBackground()
                }
        }
        .configurationDisplayName("Kozmik Durum")
        .description("Bugünün gökyüzü çarkı: Ay evresi, gezegenler, açılar, retrograd ve gezegen saati")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Ana View

struct CosmicStatusWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CosmicStatusEntry

    var body: some View {
        switch family {
        case .systemMedium: mediumView
        default:            smallView
        }
    }

    // MARK: - Small: çark + tek satır

    private var smallView: some View {
        VStack(spacing: 4) {
            WidgetSkyWheel(planets: entry.planets, moon: entry.moon, size: 110)
            HStack(spacing: 4) {
                Text(entry.moon.phase.name)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !entry.retrogrades.isEmpty {
                    Text("· ℞\(entry.retrogrades.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetPalette.retro)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Medium: solda çark, sağda bilgi sütunu

    private var mediumView: some View {
        HStack(spacing: 14) {
            WidgetSkyWheel(planets: entry.planets, moon: entry.moon, size: 126)

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.moon.phase.name)
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Text("☽\u{FE0E}")
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(WidgetPalette.planet("☽"))
                    Text("\(moonSignName) · %\(Int(entry.moon.illumination * 100)) aydınlık")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 2)

                Rectangle()
                    .fill(.white.opacity(0.10))
                    .frame(height: 1)
                    .padding(.vertical, 7)

                if let hour = entry.planetaryHour {
                    HStack(spacing: 6) {
                        Text(hour.planetSymbol + "\u{FE0E}")
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(WidgetPalette.planet(hour.planetSymbol))
                            .frame(width: 20, height: 20)
                            .background(WidgetPalette.planet(hour.planetSymbol).opacity(0.14), in: .circle)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(hour.planet) saati")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(hour.timeText)
                                .font(.system(size: 9))
                                .foregroundStyle(WidgetPalette.textTertiary)
                        }
                    }
                }

                retroLine
                    .padding(.top, 6)

                Spacer(minLength: 2)

                Text(dateText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetPalette.textTertiary)
                    .textCase(.uppercase)
                    .kerning(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    /// Ay burcu: uygulamanın yazdığı gerçek konum varsa o, yoksa yaklaşık hesap
    private var moonSignName: String {
        entry.planets.first { $0.symbol == "☽" }?.signName ?? entry.moon.moonSign.rawValue
    }

    // MARK: - Retrograd satırı

    private var retroLine: some View {
        Group {
            if entry.retrogrades.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(WidgetPalette.harmonik)
                    Text("Retrograd yok")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetPalette.textSecondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("℞")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundStyle(WidgetPalette.retro)
                    Text(entry.retrogrades.joined(separator: " · "))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetPalette.retro.opacity(0.9))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    // MARK: - Yardımcılar

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: entry.date)
    }
}
