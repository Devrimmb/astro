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
                    Color(red: 0.05, green: 0.06, blue: 0.15)
                }
        }
        .configurationDisplayName("Kozmik Durum")
        .description("Ay fazı, retrograd, gezegen saati ve bugünün gezegenleri")
        .supportedFamilies([.systemSmall, .systemMedium])
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

    // MARK: - Small: Ay + 4 İç Gezegen + Retrograd

    private var smallView: some View {
        VStack(spacing: 0) {
            // Ay fazı (üst)
            VStack(spacing: 3) {
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.system(size: 38))
                    .foregroundStyle(.yellow.opacity(0.85))
                Text(entry.moon.phase.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                HStack(spacing: 3) {
                    Text(entry.moon.moonSign.glyph)
                    Text(entry.moon.moonSign.rawValue)
                        .lineLimit(1)
                }
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.6))
            }

            Rectangle()
                .fill(.white.opacity(0.07))
                .frame(height: 1)
                .padding(.vertical, 5)

            // 4 iç gezegen yatay
            let inner = entry.planets.prefix(4)  // Sun, Moon, Mercury, Venus
            HStack(spacing: 0) {
                ForEach(inner, id: \.name) { p in
                    VStack(spacing: 2) {
                        Text(p.symbol)
                            .font(.system(size: 13))
                            .foregroundStyle(planetColor(p.symbol))
                        Text(p.signGlyph)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Spacer(minLength: 4)

            // Retrograd
            retroBadgeRow
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
    }

    // MARK: - Medium: Kombo C — Üst Şerit + Alt 5×2 Izgara

    private var mediumView: some View {
        VStack(spacing: 0) {
            // ── Üst şerit ──
            HStack(spacing: 8) {
                // Ay
                HStack(spacing: 6) {
                    Image(systemName: entry.moon.phase.sfSymbol)
                        .font(.system(size: 26))
                        .foregroundStyle(.yellow.opacity(0.85))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.moon.phase.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        HStack(spacing: 3) {
                            Text(entry.moon.moonSign.glyph)
                            Text(entry.moon.moonSign.rawValue)
                        }
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.55))
                        Text("%\(Int(entry.moon.illumination * 100)) aydın.")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Rectangle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 1)
                    .padding(.vertical, 2)

                // Retrogradlar
                VStack(alignment: .leading, spacing: 2) {
                    if entry.retrogrades.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.green.opacity(0.7))
                            Text("Retrograd yok")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    } else {
                        ForEach(entry.retrogrades.prefix(3), id: \.self) { p in
                            HStack(spacing: 3) {
                                Text("℞")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.red.opacity(0.85))
                                Text(p)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.red.opacity(0.9))
                            }
                        }
                    }
                }

                Spacer()

                // Gezegen saati + tarih
                VStack(alignment: .trailing, spacing: 2) {
                    if let hour = entry.planetaryHour {
                        HStack(spacing: 3) {
                            Text(hour.planetSymbol)
                                .font(.system(size: 11))
                                .foregroundStyle(.purple.opacity(0.8))
                            Text(hour.planet)
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    Text(shortDateText)
                        .font(.system(size: 7))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle()
                .fill(.white.opacity(0.07))
                .frame(height: 1)
                .padding(.horizontal, 6)

            // ── Alt 5×2 gezegen ızgarası ──
            if entry.planets.isEmpty {
                Spacer()
                Text("Uygulama açıldığında güncellenir")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Spacer()
            } else {
                let rows = [
                    Array(entry.planets.prefix(5)),
                    Array(entry.planets.dropFirst(5).prefix(5))
                ]
                VStack(spacing: 4) {
                    ForEach(0..<rows.count, id: \.self) { rowIdx in
                        HStack(spacing: 4) {
                            ForEach(rows[rowIdx], id: \.name) { p in
                                planetGridCell(p, isRetro: p.isRetrograde)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Gezegen Izgara Hücresi

    private func planetGridCell(_ planet: WidgetPlanetInfo, isRetro: Bool) -> some View {
        VStack(spacing: 2) {
            Text(planet.symbol)
                .font(.system(size: 14))
                .foregroundStyle(planetColor(planet.symbol))

            Text(planet.name)
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 1) {
                Text(planet.signGlyph)
                Text(shortSign(planet.signName))
            }
            .font(.system(size: 7))
            .foregroundStyle(isRetro ? .red.opacity(0.8) : .white.opacity(0.45))

            if isRetro {
                Text("℞")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.red.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(
            isRetro
                ? Color.red.opacity(0.07)
                : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            isRetro
                ? RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1)
                : nil
        )
    }

    // MARK: - Retrograd badge satırı (small için)

    private var retroBadgeRow: some View {
        Group {
            if entry.retrogrades.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green.opacity(0.7))
                    Text("Retrograd yok")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.45))
                }
            } else {
                HStack(spacing: 3) {
                    Text("℞")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.red.opacity(0.85))
                    Text(entry.retrogrades.prefix(2).joined(separator: ", "))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    // MARK: - Yardımcılar

    private func planetColor(_ symbol: String) -> Color {
        switch symbol {
        case "☉": return Color(red: 0.94, green: 0.75, blue: 0.25)
        case "☽": return Color(red: 0.31, green: 0.76, blue: 0.97)
        case "♀": return Color(red: 0.96, green: 0.56, blue: 0.69)
        case "♂": return Color(red: 0.94, green: 0.32, blue: 0.31)
        case "♃": return Color(red: 1.00, green: 0.70, blue: 0.00)
        case "♄": return Color(red: 0.56, green: 0.64, blue: 0.68)
        case "⛢": return Color(red: 0.50, green: 0.79, blue: 0.77)
        case "♆": return Color(red: 0.47, green: 0.53, blue: 0.80)
        case "♇": return Color(red: 0.81, green: 0.58, blue: 0.85)
        default:  return .white.opacity(0.7)
        }
    }

    private func shortSign(_ name: String) -> String {
        switch name {
        case "İkizler":     "İkiz"
        case "Yengeç":      "Yenç"
        case "Terazi":      "Ter."
        case "Akrep":       "Akrp"
        case "Yay":         "Yay"
        case "Oğlak":       "Oğlk"
        case "Kova":        "Kova"
        case "Balık":       "Balık"
        default:             name.prefix(4).description
        }
    }

    private var shortDateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM, EEE"
        return f.string(from: entry.date)
    }
}
