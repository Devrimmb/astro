//
//  MoonPhaseWidget.swift
//  AstroWidget
//
//  Created by Devrim Bal on 13.03.2026.
//

import WidgetKit
import SwiftUI

// MARK: - Moon Phase Widget

struct MoonPhaseEntry: TimelineEntry {
    let date: Date
    let moon: WidgetMoonInfo
}

struct MoonPhaseProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoonPhaseEntry {
        MoonPhaseEntry(date: .now, moon: WidgetMoonCalculator.current())
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonPhaseEntry) -> Void) {
        completion(MoonPhaseEntry(date: .now, moon: WidgetMoonCalculator.current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonPhaseEntry>) -> Void) {
        var entries: [MoonPhaseEntry] = []
        let now = Date.now

        // Her 6 saatte bir guncelle (ay fazi yavas degisir)
        for hourOffset in stride(from: 0, to: 48, by: 6) {
            let date = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            entries.append(MoonPhaseEntry(date: date, moon: WidgetMoonCalculator.current(for: date)))
        }

        let nextDay = Calendar.current.startOfDay(for: now.addingTimeInterval(86400 * 2))
        completion(Timeline(entries: entries, policy: .after(nextDay)))
    }
}

struct MoonPhaseWidget: Widget {
    let kind = "MoonPhaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoonPhaseProvider()) { entry in
            MoonPhaseWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                }
        }
        .configurationDisplayName("Ay Fazi")
        .description("Guncel ay fazi ve ay burcu")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Moon Phase Views

struct MoonPhaseWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MoonPhaseEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.moon.phase.sfSymbol)
                .font(.system(size: 40))
                .foregroundStyle(.yellow.opacity(0.8))

            Text(entry.moon.phase.name)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("%\(Int(entry.moon.illumination * 100)) aydinlanma")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 3) {
                Text(entry.moon.moonSign.glyph)
                    .font(.caption)
                Text(entry.moon.moonSign.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(2)
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: entry.moon.phase.sfSymbol)
                    .font(.title3)
                Text("%\(Int(entry.moon.illumination * 100))")
                    .font(.system(size: 9))
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.moon.phase.sfSymbol)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.moon.phase.name)
                    .font(.caption.bold())
                Text("\(entry.moon.moonSign.glyph) \(entry.moon.moonSign.rawValue)")
                    .font(.caption2)
            }
        }
    }
}
