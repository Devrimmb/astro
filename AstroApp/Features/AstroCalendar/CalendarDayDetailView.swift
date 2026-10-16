import SwiftUI

struct CalendarDayDetailView: View {
    let summary: CalendarDaySummary

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                if let tip = summary.dailyTip {
                    tipCard(tip)
                }
                if let moon = summary.moonPhase {
                    moonCard(moon)
                }
                if !summary.events.isEmpty {
                    eventsCard
                }
            }
            .padding()
            .padding(.bottom, 20)
        }
        .background(SubtleStarsBackground())
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(formattedDate)
                .font(.title2)
                    .fontDesign(.serif)
                .foregroundStyle(.white)
            if let moon = summary.moonPhase {
                HStack(spacing: 6) {
                    Text(moon.phase.emoji)
                        .font(.title3)
                    Text(moon.phase.name)
                        .font(.subheadline)
                        .foregroundStyle(AstroTheme.textSecondary)
                    if let sign = moon.moonSign {
                        Text("·")
                            .foregroundStyle(AstroTheme.textTertiary)
                        Text("\(sign.glyph) \(sign.name)")
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.planet(.moon))
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Daily Tip

    private func tipCard(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(AstroTheme.planet(.sun))
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Günün Tavsiyesi")
                    .font(.caption.bold())
                    .foregroundStyle(AstroTheme.textSecondary)
                Text(tip)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .glassCard()
    }

    // MARK: - Moon Phase

    private func moonCard(_ moon: MoonPhaseInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "moon.stars")
                    .foregroundStyle(AstroTheme.planet(.moon))
                Text("Ay Fazı")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(moon.phase.emoji)
                        .font(.system(size: 44))
                    Text("% \(String(format: "%.0f", moon.illumination * 100))")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(moon.phase.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(moon.phase.description)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }

            if !moon.phase.energies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(moon.phase.energies, id: \.self) { energy in
                            Text(energy)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AstroTheme.surface, in: .capsule)
                                .foregroundStyle(AstroTheme.planet(.moon))
                        }
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Events

    private var eventsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(AstroTheme.accent)
                Text("Olaylar (\(summary.events.count))")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(summary.events) { event in
                HStack(spacing: 10) {
                    Image(systemName: event.icon)
                        .font(.caption)
                        .foregroundStyle(eventColor(event.type))
                        .frame(width: 28, height: 28)
                        .background(eventColor(event.type).opacity(0.15), in: .rect(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                        Text(event.subtitle)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textSecondary)
                    }

                    Spacer()

                    Text(eventTime(event.date))
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
                .padding(.vertical, 2)

                if event.id != summary.events.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: summary.date)
    }

    private func eventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func eventColor(_ type: CalendarEventType) -> Color {
        switch type {
        case .moonPhase: AstroTheme.planet(.moon)
        case .eclipse: AstroTheme.accent
        case .retrograde: AstroTheme.zorlayici
        case .voidOfCourse: Color(red: 0.6, green: 0.5, blue: 0.8)
        case .planetaryHour: AstroTheme.planet(.saturn)
        }
    }
}
