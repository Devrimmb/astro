import WidgetKit
import SwiftUI

// MARK: - Entry

struct CosmicStatusEntry: TimelineEntry {
    let date: Date
    let moon: WidgetMoonInfo
    let retrogrades: [String]
    let planetaryHour: WidgetPlanetaryHour?
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
        // Gezegen saati her saat değişir
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
            planetaryHour: WidgetPlanetaryHourCalculator.currentHour(date: date, latitude: lat, longitude: lon)
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
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Kozmik Durum")
        .description("Ay fazı, retrograd durumu ve gezegen saati")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct CosmicStatusWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CosmicStatusEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Kare (Small)

    private var smallView: some View {
        VStack(spacing: 0) {
            // Ay ikonu büyük
            Image(systemName: entry.moon.phase.sfSymbol)
                .font(.system(size: 44))
                .foregroundStyle(.yellow.opacity(0.85))
                .padding(.bottom, 6)

            // Faz adı
            Text(entry.moon.phase.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Ay burcu + aydınlanma
            HStack(spacing: 4) {
                Text(entry.moon.moonSign.glyph)
                    .font(.caption)
                Text(entry.moon.moonSign.rawValue)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.top, 3)

            Spacer()

            // Retrograd durumu
            retroStatusBadge
                .padding(.top, 4)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }

    // MARK: - Dikdörtgen (Medium)

    private var mediumView: some View {
        HStack(spacing: 0) {
            // Sol: Ay fazı
            VStack(spacing: 4) {
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow.opacity(0.85))

                Text(entry.moon.phase.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 3) {
                    Text(entry.moon.moonSign.glyph)
                        .font(.caption)
                    Text(entry.moon.moonSign.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Text("%\(Int(entry.moon.illumination * 100)) aydınlanma")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 90)

            // Ayırıcı
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // Sağ: İpucu + Retro + Gezegen saati + Tarih
            VStack(alignment: .leading, spacing: 6) {
                // Ay fazı ipucu
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow.opacity(0.7))
                    Text(entry.moon.phase.shortTip)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                Divider().opacity(0.15)

                // Retrograd listesi
                if entry.retrogrades.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.green.opacity(0.7))
                        Text("Retrograd yok")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                } else {
                    ForEach(entry.retrogrades.prefix(3), id: \.self) { planet in
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange.opacity(0.8))
                            Text("\(planet) ℞")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.orange.opacity(0.9))
                        }
                    }
                }

                Spacer()

                // Gezegen saati + tarih
                HStack {
                    if let hour = entry.planetaryHour {
                        HStack(spacing: 3) {
                            Text(hour.planetSymbol)
                                .font(.system(size: 11))
                                .foregroundStyle(.purple.opacity(0.8))
                            Text(hour.planet)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    Spacer()
                    Text(dateText)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.leading, 10)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    // MARK: - Retrograd Rozeti (small için)

    private var retroStatusBadge: some View {
        Group {
            if entry.retrogrades.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green.opacity(0.7))
                    Text("Retrograd yok")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.8))
                    Text(entry.retrogrades.prefix(2).joined(separator: ", ") + " ℞")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: entry.date)
    }
}
