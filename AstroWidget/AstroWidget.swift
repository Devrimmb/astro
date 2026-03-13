//
//  AstroWidget.swift
//  AstroWidget
//
//  Created by Devrim Bal on 13.03.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Astro Summary Widget (Genel Ozet)

struct AstroSummaryEntry: TimelineEntry {
    let date: Date
    let sign: WidgetZodiacSign
    let horoscope: WidgetHoroscope
    let moon: WidgetMoonInfo
    let planetaryHour: WidgetPlanetaryHour?
}

struct AstroSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> AstroSummaryEntry {
        makeEntry(for: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (AstroSummaryEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AstroSummaryEntry>) -> Void) {
        var entries: [AstroSummaryEntry] = []
        let now = Date.now

        // Her saat icin entry olustur (gezegen saati degisir)
        for hourOffset in 0..<12 {
            let date = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            entries.append(makeEntry(for: date))
        }

        // Gece yarisi yenile (gunluk burc degisir)
        let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }

    private func makeEntry(for date: Date) -> AstroSummaryEntry {
        let sign = WidgetSharedDefaults.userSign
        let lat = WidgetSharedDefaults.latitude
        let lon = WidgetSharedDefaults.longitude

        return AstroSummaryEntry(
            date: date,
            sign: sign,
            horoscope: WidgetHoroscopeGenerator.generate(for: sign, date: date),
            moon: WidgetMoonCalculator.current(for: date),
            planetaryHour: WidgetPlanetaryHourCalculator.currentHour(date: date, latitude: lat, longitude: lon)
        )
    }
}

struct AstroSummaryWidget: Widget {
    let kind = "AstroSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AstroSummaryProvider()) { entry in
            AstroSummaryWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Astro Ozet")
        .description("Gunluk burc, ay fazi ve gezegen saati")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Summary Widget Views

struct AstroSummaryWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AstroSummaryEntry

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
                Text(entry.sign.glyph)
                    .font(.title)
                Spacer()
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(.yellow.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.sign.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.horoscope.overall ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(i < entry.horoscope.overall ? .orange : .gray.opacity(0.4))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let hour = entry.planetaryHour {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.purple.opacity(0.8))
                    Text(hour.planet)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(2)
    }

    // MARK: Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ust: Burc + tarih + yildizlar
            HStack {
                Text(entry.sign.glyph)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.sign.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(dateText)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.horoscope.overall ? "star.fill" : "star")
                            .font(.system(size: 9))
                            .foregroundStyle(i < entry.horoscope.overall ? .orange : .gray.opacity(0.3))
                    }
                }
            }

            // Orta: Gunluk yorum
            Text(entry.horoscope.text)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)

            // Alt: Ay + Gezegen saati
            HStack(spacing: 14) {
                Label(entry.moon.phase.name, systemImage: entry.moon.phase.sfSymbol)
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow.opacity(0.7))

                if let hour = entry.planetaryHour {
                    Label(hour.planet, systemImage: "clock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.purple.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 8) {
                    moodMini(title: "A", rating: entry.horoscope.love, color: .red)
                    moodMini(title: "K", rating: entry.horoscope.career, color: .purple)
                    moodMini(title: "S", rating: entry.horoscope.health, color: .green)
                    moodMini(title: "Ş", rating: entry.horoscope.luck, color: .orange)
                }
            }
        }
        .padding(2)
    }

    private func moodMini(title: String, rating: Int, color: Color) -> some View {
        HStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.4))
            Text("\(rating)")
                .font(.system(size: 8).bold())
                .foregroundStyle(color.opacity(0.8))
        }
    }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: entry.date)
    }
}
