import SwiftUI

struct EclipseView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var eclipses: [Eclipse] = []
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
                    } else if eclipses.isEmpty {
                        Text("Bu yıl için tutulma bulunamadı.")
                            .font(.subheadline)
                            .foregroundStyle(AstroTheme.textSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(eclipses) { eclipse in
                            eclipseCard(eclipse)
                        }
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Tutulmalar")
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

    private func eclipseCard(_ eclipse: Eclipse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: eclipse.isSolar ? "sun.max.trianglebadge.exclamationmark" : "moon.circle")
                    .font(.title2)
                    .foregroundStyle(eclipse.isSolar ? .orange : .cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(eclipse.type.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(eclipse.dateText)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(eclipse.sign.glyph)
                        .font(.title3)
                    Text("\(eclipse.sign.name) \(String(format: "%.0f", eclipse.degree))°")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
            }

            // Natal haritaya etkisi
            if let chart = appState.currentChart {
                let affected = eclipse.affectsNatalPlanet(chart.planets)
                if !affected.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Etkilenen: \(affected.map(\.rawValue).joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .glassCard()
    }

    private func loadData() async {
        isLoading = true
        eclipses = EclipseCalculator.calculate(year: selectedYear)
        isLoading = false
    }
}
