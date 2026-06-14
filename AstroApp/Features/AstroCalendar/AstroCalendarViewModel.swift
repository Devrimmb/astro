import Foundation

@Observable
final class AstroCalendarViewModel {
    var currentMonth: Date = .now
    var daySummaries: [String: CalendarDaySummary] = [:]
    var selectedDay: CalendarDaySummary?
    var isLoading = false

    private let calendar = Calendar.current

    // MARK: - Month Navigation

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth).capitalized
    }

    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    var firstWeekdayOffset: Int {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return 0 }
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        // Pazartesi = 0, Pazar = 6
        return (weekday + 5) % 7
    }

    func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Data Loading

    func loadMonth() async {
        isLoading = true

        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))
        else {
            isLoading = false
            return
        }

        let days = daysInMonth

        // Tüm hesaplamaları paralel çalıştır
        let eclipses = EclipseCalculator.calculate(year: year)
        let retrogrades = RetrogradeCalculator.calculate(year: year)
        let vocPeriods = VoidOfCourseCalculator.calculate(fromDate: firstOfMonth, days: daysInMonth.count + 1)

        var summaries: [String: CalendarDaySummary] = [:]

        for date in days {
            let key = dayKey(for: date)
            var events: [CalendarEvent] = []

            // Ay Fazı
            let moonPhase = MoonPhaseCalculator.phaseInfo(for: date)
            let isSignificantPhase = [MoonPhaseName.newMoon, .fullMoon, .firstQuarter, .lastQuarter].contains(moonPhase.phase)
            if isSignificantPhase {
                events.append(CalendarEvent(
                    date: date,
                    type: .moonPhase,
                    title: moonPhase.phase.name,
                    subtitle: moonPhase.moonSign?.name ?? "",
                    icon: moonPhase.phase.symbolName
                ))
            }

            // Tutulmalar
            let dayEclipses = eclipses.filter { calendar.isDate($0.date, inSameDayAs: date) }
            for eclipse in dayEclipses {
                events.append(CalendarEvent(
                    date: eclipse.date,
                    type: .eclipse,
                    title: eclipse.type.rawValue,
                    subtitle: "\(eclipse.sign.name) \(String(format: "%.0f", eclipse.degree))°",
                    icon: eclipse.isSolar ? "sun.max.trianglebadge.exclamationmark" : "moon.circle"
                ))
            }

            // Retrograde başlangıç/bitiş
            for retro in retrogrades {
                if calendar.isDate(retro.startDate, inSameDayAs: date) {
                    events.append(CalendarEvent(
                        date: retro.startDate,
                        type: .retrograde,
                        title: "\(retro.planet.name) Retrograde Başlangıç",
                        subtitle: "\(retro.startSign.name) — \(retro.durationDays) gün",
                        icon: "arrow.backward.circle.fill"
                    ))
                }
                if calendar.isDate(retro.endDate, inSameDayAs: date) {
                    events.append(CalendarEvent(
                        date: retro.endDate,
                        type: .retrograde,
                        title: "\(retro.planet.name) Retrograde Bitiş",
                        subtitle: retro.endSign.name,
                        icon: "arrow.forward.circle.fill"
                    ))
                }
            }

            // VOC dönemleri
            let dayVOCs = vocPeriods.filter { voc in
                calendar.isDate(voc.startDate, inSameDayAs: date) || calendar.isDate(voc.endDate, inSameDayAs: date)
            }
            for voc in dayVOCs {
                if calendar.isDate(voc.startDate, inSameDayAs: date) {
                    events.append(CalendarEvent(
                        date: voc.startDate,
                        type: .voidOfCourse,
                        title: "Ay Boşlukta",
                        subtitle: "\(voc.fromSign.name) → \(voc.toSign.name) · \(voc.durationText)",
                        icon: "moon.haze"
                    ))
                }
            }

            // Aktif retrograde'ler
            let activeRetros = retrogrades.filter { $0.startDate <= date && date <= $0.endDate }
            let isVOC = vocPeriods.contains { $0.startDate <= date && date <= $0.endDate }
            let hasEclipse = !dayEclipses.isEmpty

            let tip = DailyTipGenerator.generate(
                moonPhase: moonPhase,
                isVOC: isVOC,
                activeRetrogrades: activeRetros,
                hasEclipse: hasEclipse
            )

            summaries[key] = CalendarDaySummary(
                id: key,
                date: date,
                events: events,
                moonPhase: moonPhase,
                dailyTip: tip
            )
        }

        daySummaries = summaries
        isLoading = false
    }

    func summary(for date: Date) -> CalendarDaySummary? {
        daySummaries[dayKey(for: date)]
    }
}
