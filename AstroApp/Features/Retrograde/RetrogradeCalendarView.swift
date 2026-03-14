import SwiftUI

struct RetrogradeCalendarView: View {
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var periods: [RetrogradeCalculator.RetrogradePeriod] = []
    @State private var isLoading = false

    private var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: .now)
        return Array((current - 1)...(current + 2))
    }

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    yearSelector
                    if isLoading {
                        ProgressView("Hesaplanıyor...")
                            .tint(AstroTheme.accent)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        activeRetrogrades
                        allPeriods
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Retrograde Takvimi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadData() }
        .onChange(of: selectedYear) { Task { await loadData() } }
    }

    private var yearSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        selectedYear = year
                    } label: {
                        Text(String(year))
                            .font(.subheadline.bold())
                            .foregroundStyle(selectedYear == year ? .white : AstroTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedYear == year
                                    ? AnyShapeStyle(AstroTheme.accentGradient.opacity(0.5))
                                    : AnyShapeStyle(AstroTheme.surface),
                                in: .capsule
                            )
                    }
                }
            }
        }
    }

    private var activeRetrogrades: some View {
        let active = periods.filter { $0.isActive }
        return Group {
            if !active.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Şu An Retrograde")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    ForEach(active) { period in
                        retrogradeRow(period, highlight: true)
                    }
                }
                .glassCard()
            }
        }
    }

    private var allPeriods: some View {
        let grouped = Dictionary(grouping: periods) { $0.planet }
        let sortedPlanets = grouped.keys.sorted {
            Planet.allCases.firstIndex(of: $0)! < Planet.allCases.firstIndex(of: $1)!
        }

        return ForEach(sortedPlanets, id: \.self) { planet in
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(planet.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("℞")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                ForEach(grouped[planet] ?? []) { period in
                    retrogradeRow(period, highlight: false)
                }
            }
            .glassCard()
        }
    }

    private func retrogradeRow(_ period: RetrogradeCalculator.RetrogradePeriod, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(period.startText) → \(period.endText)")
                    .font(.caption.bold())
                    .foregroundStyle(highlight ? .orange : .white)
                Spacer()
                Text("\(period.durationDays) gün")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
            HStack(spacing: 4) {
                Text(period.startSign.glyph)
                    .font(.caption2)
                Text(period.startSign.name)
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textSecondary)
                if period.startSign != period.endSign {
                    Text("→")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                    Text(period.endSign.glyph)
                        .font(.caption2)
                    Text(period.endSign.name)
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func loadData() async {
        isLoading = true
        periods = RetrogradeCalculator.calculate(year: selectedYear)
        isLoading = false
    }
}
