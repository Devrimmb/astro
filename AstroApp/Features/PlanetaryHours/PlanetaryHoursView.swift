import SwiftUI

struct PlanetaryHoursView: View {
    @Environment(AppState.self) private var appState
    @State private var dailyHours: DailyPlanetaryHours?

    var body: some View {
        ZStack {
            SubtleStarsBackground()

            ScrollView {
                VStack(spacing: 16) {
                    if let hours = dailyHours {
                        currentHourCard(hours)
                        dayHoursCard(hours)
                        nightHoursCard(hours)
                    } else {
                        ProgressView()
                            .tint(AstroTheme.accent)
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Gezegen Saatleri")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { loadData() }
    }

    private func currentHourCard(_ hours: DailyPlanetaryHours) -> some View {
        let current = hours.currentHour
        return VStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundStyle(planetColor(current?.planet ?? .sun))

            Text("Şu Anki Gezegen Saati")
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)

            Text(current?.planet.name ?? "—")
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let current {
                Text(current.timeText)
                    .font(.subheadline)
                    .foregroundStyle(AstroTheme.textSecondary)

                Text(current.meaning)
                    .font(.caption)
                    .foregroundStyle(AstroTheme.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .glassCard()
    }

    private func dayHoursCard(_ hours: DailyPlanetaryHours) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.orange)
                Text("Gündüz Saatleri")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(hours.hours.filter { $0.isDayHour }) { hour in
                hourRow(hour)
            }
        }
        .glassCard()
    }

    private func nightHoursCard(_ hours: DailyPlanetaryHours) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "moon.fill")
                    .foregroundStyle(.cyan)
                Text("Gece Saatleri")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            ForEach(hours.hours.filter { !$0.isDayHour }) { hour in
                hourRow(hour)
            }
        }
        .glassCard()
    }

    private func hourRow(_ hour: PlanetaryHour) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(planetColor(hour.planet))
                .frame(width: 8, height: 8)

            Text("\(hour.hourNumber).")
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
                .frame(width: 20)

            Text(hour.planet.name)
                .font(.caption.bold())
                .foregroundStyle(hour.isActive ? .orange : .white)
                .frame(width: 60, alignment: .leading)

            Text(hour.timeText)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)

            Spacer()

            if hour.isActive {
                Text("AKTİF")
                    .font(.caption2.bold())
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.15), in: .capsule)
            }
        }
        .padding(.vertical, 1)
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun: .orange
        case .moon: .white
        case .mars: .red
        case .mercury: .cyan
        case .jupiter: .purple
        case .venus: .pink
        case .saturn: .brown
        default: AstroTheme.accent
        }
    }

    private func loadData() {
        let lat = appState.currentChart?.latitude ?? 41.0082
        let lon = appState.currentChart?.longitude ?? 28.9784
        dailyHours = PlanetaryHourCalculator.calculate(date: .now, latitude: lat, longitude: lon)
    }
}
