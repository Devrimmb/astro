//
//  DailyHoroscopeWidget.swift
//  AstroWidget
//
//  Created by Devrim Bal on 13.03.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Daily Horoscope Widget

struct HoroscopeEntry: TimelineEntry {
    let date: Date
    let horoscope: WidgetHoroscope
}

struct HoroscopeProvider: TimelineProvider {
    func placeholder(in context: Context) -> HoroscopeEntry {
        let sign = WidgetSharedDefaults.userSign
        return HoroscopeEntry(date: .now, horoscope: WidgetHoroscopeGenerator.generate(for: sign))
    }

    func getSnapshot(in context: Context, completion: @escaping (HoroscopeEntry) -> Void) {
        let sign = WidgetSharedDefaults.userSign
        completion(HoroscopeEntry(date: .now, horoscope: WidgetHoroscopeGenerator.generate(for: sign)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoroscopeEntry>) -> Void) {
        let sign = WidgetSharedDefaults.userSign
        let entry = HoroscopeEntry(date: .now, horoscope: WidgetHoroscopeGenerator.generate(for: sign))

        // Gece yarisi yenile
        let tomorrow = Calendar.current.startOfDay(for: Date.now.addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }
}

struct DailyHoroscopeWidget: Widget {
    let kind = "DailyHoroscopeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HoroscopeProvider()) { entry in
            HoroscopeWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Gunluk Burc")
        .description("Gunluk burc yorumunuz")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Horoscope Widget Views

struct HoroscopeWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: HoroscopeEntry

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 6) {
            HStack {
                Text(entry.horoscope.sign.glyph)
                    .font(.title)
                Spacer()
                starRating(entry.horoscope.overall)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.horoscope.sign.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(entry.horoscope.text)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(2)
    }

    private var mediumView: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(entry.horoscope.sign.glyph)
                    .font(.system(size: 36))
                Text(entry.horoscope.sign.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                starRating(entry.horoscope.overall)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.horoscope.text)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(4)

                Spacer()

                HStack(spacing: 0) {
                    moodMini(title: "Ask", rating: entry.horoscope.love, color: .red)
                    moodMini(title: "Kariyer", rating: entry.horoscope.career, color: .purple)
                    moodMini(title: "Saglik", rating: entry.horoscope.health, color: .green)
                    moodMini(title: "Sans", rating: entry.horoscope.luck, color: .orange)
                }
            }
        }
        .padding(2)
    }

    private func starRating(_ rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(i < rating ? .orange : .gray.opacity(0.4))
            }
        }
    }

    private func moodMini(title: String, rating: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < rating ? color : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
