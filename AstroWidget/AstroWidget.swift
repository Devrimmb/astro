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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Summary Widget Views

struct AstroSummaryWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: AstroSummaryEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
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
        HStack(spacing: 14) {
            // Sol: Burc + rating
            VStack(spacing: 8) {
                Text(entry.sign.glyph)
                    .font(.system(size: 36))
                Text(entry.sign.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.horoscope.overall ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(i < entry.horoscope.overall ? .orange : .gray.opacity(0.4))
                    }
                }
            }
            .frame(width: 80)

            // Sag: Detaylar
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.horoscope.text)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(3)

                Spacer()

                HStack(spacing: 12) {
                    Label(entry.moon.phase.name, systemImage: entry.moon.phase.sfSymbol)
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow.opacity(0.8))

                    if let hour = entry.planetaryHour {
                        Label(hour.planet, systemImage: "clock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.purple.opacity(0.8))
                    }
                }
            }
        }
        .padding(2)
    }

    // MARK: Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Baslik
            HStack {
                Text(entry.sign.glyph)
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.sign.rawValue)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.horoscope.overall ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i < entry.horoscope.overall ? .orange : .gray.opacity(0.4))
                    }
                }
            }

            // Gunluk yorum
            Text(entry.horoscope.text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)

            Divider().overlay(Color.white.opacity(0.1))

            // Mood
            HStack(spacing: 0) {
                moodDot(title: "Ask", rating: entry.horoscope.love, color: .red)
                moodDot(title: "Kariyer", rating: entry.horoscope.career, color: .purple)
                moodDot(title: "Saglik", rating: entry.horoscope.health, color: .green)
                moodDot(title: "Sans", rating: entry.horoscope.luck, color: .orange)
            }

            Divider().overlay(Color.white.opacity(0.1))

            // Ay & Gezegen Saati
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: entry.moon.phase.sfSymbol)
                        .font(.title3)
                        .foregroundStyle(.yellow.opacity(0.8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.moon.phase.name)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                        Text("\(entry.moon.moonSign.glyph) \(entry.moon.moonSign.rawValue)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                if let hour = entry.planetaryHour {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.purple.opacity(0.8))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(hour.planet)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                            Text(hour.timeText)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(4)
    }

    private func moodDot(title: String, rating: Int, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < rating ? color : Color.gray.opacity(0.3))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM, EEEE"
        return f.string(from: entry.date)
    }
}
