import SwiftUI

struct BirthChartInputView: View {
    @Environment(AppState.self) private var appState
    @State private var calculatedChart: BirthChart?
    @State private var isCalculating = false
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text("Doğum Haritası")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                            Text("Yıldızların sana ne söylüyor?")
                                .font(.subheadline)
                                .foregroundStyle(AstroTheme.textSecondary)
                        }
                        .padding(.top, 20)

                        PersonSelectionCard(
                            title: "Kişi Seçin",
                            buttonTitle: isCalculating ? "Hesaplanıyor..." : "Haritayı Hesapla",
                            buttonIcon: "star.circle.fill"
                        ) { birthData in
                            Task { await calculateChart(for: birthData) }
                        }
                        .disabled(isCalculating)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showResult) {
                if let chart = calculatedChart {
                    BirthChartResultView(chart: chart)
                }
            }
        }
    }

    private func calculateChart(for data: BirthData) async {
        isCalculating = true
        let chart = await appState.ephemeris.calculateBirthChart(
            date: data.birthDate,
            latitude: data.latitude,
            longitude: data.longitude,
            timeZone: TimeZone(identifier: "Europe/Istanbul")!
        )
        calculatedChart = chart
        isCalculating = false
        showResult = true
    }
}
