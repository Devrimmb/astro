import SwiftUI

struct AstroCalendarContent: View {
    @State private var viewModel = AstroCalendarViewModel()
    @State private var selectedSummary: CalendarDaySummary?

    private let weekdays = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            if viewModel.isLoading {
                ProgressView("Yükleniyor...")
                    .tint(AstroTheme.accent)
                    .foregroundStyle(AstroTheme.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        monthNavigator
                        weekdayHeader
                        calendarGrid
                        todaySummaryCard
                        legendCard
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Astro Takvim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.loadMonth() }
        .onChange(of: viewModel.currentMonth) { Task { await viewModel.loadMonth() } }
        .sheet(item: $selectedSummary) { summary in
            CalendarDayDetailView(summary: summary)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AstroTheme.accent)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AstroTheme.accent)
                    .frame(width: 44, height: 44)
            }
        }
        .glassCard()
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption2.bold())
                    .foregroundStyle(AstroTheme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                Color.clear
                    .frame(height: 56)
            }

            ForEach(viewModel.daysInMonth, id: \.self) { date in
                dayCell(date)
            }
        }
        .glassCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let summary = viewModel.summary(for: date)
        let isToday = viewModel.isToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)

        return Button {
            if let summary {
                selectedSummary = summary
            }
        } label: {
            VStack(spacing: 3) {
                Text(summary?.moonPhase?.phase.emoji ?? " ")
                    .font(.system(size: 14))

                Text("\(dayNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? .white : AstroTheme.textSecondary)

                HStack(spacing: 2) {
                    if let types = summary?.eventTypes, !types.isEmpty {
                        ForEach(Array(types.prefix(3).enumerated()), id: \.offset) { _, type in
                            Circle()
                                .fill(eventColor(type))
                                .frame(width: 4, height: 4)
                        }
                    } else {
                        Color.clear.frame(width: 4, height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isToday
                    ? AnyShapeStyle(AstroTheme.accentGradient.opacity(0.3))
                    : AnyShapeStyle(Color.clear),
                in: .rect(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? AstroTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Today Summary

    private var todaySummaryCard: some View {
        Group {
            if let today = viewModel.summary(for: .now) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(.orange)
                        Text("Bugün")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    if let moon = today.moonPhase {
                        HStack(spacing: 8) {
                            Text(moon.phase.emoji)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(moon.phase.name)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                if let sign = moon.moonSign {
                                    Text("Ay \(sign.glyph) \(sign.name) burcunda")
                                        .font(.caption)
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }

                    if let tip = today.dailyTip {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(AstroTheme.textSecondary)
                        }
                    }

                    if !today.events.isEmpty {
                        Divider().overlay(AstroTheme.cardBorder)
                        ForEach(today.events) { event in
                            HStack(spacing: 8) {
                                Image(systemName: event.icon)
                                    .font(.caption2)
                                    .foregroundStyle(eventColor(event.type))
                                Text(event.title)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(event.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(AstroTheme.textTertiary)
                            }
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    // MARK: - Legend

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Simgeler")
                .font(.caption.bold())
                .foregroundStyle(AstroTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(CalendarEventType.allCases, id: \.rawValue) { type in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(eventColor(type))
                            .frame(width: 6, height: 6)
                        Text(type.rawValue)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Spacer()
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func eventColor(_ type: CalendarEventType) -> Color {
        switch type {
        case .moonPhase: .cyan
        case .eclipse: .indigo
        case .retrograde: .red
        case .voidOfCourse: Color(red: 0.6, green: 0.5, blue: 0.8)
        case .planetaryHour: .brown
        }
    }
}
