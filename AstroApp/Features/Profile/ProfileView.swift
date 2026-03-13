import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        if let data = appState.birthDataStore.savedData {
                            profileCard(data)
                            if let chart = appState.currentChart {
                                bigThreeSummary(chart)
                                elementSummary(chart)
                            }
                            recalculateButton
                        } else {
                            emptyState
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Profil Kartı

    private func profileCard(_ data: BirthData) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AstroTheme.accent)

            if !data.name.isEmpty {
                Text(data.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                infoRow(icon: "calendar", text: formattedDate(data.birthDate))
                infoRow(icon: "clock", text: formattedTime(data.birthDate))
                infoRow(icon: "mappin.circle", text: data.cityName)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AstroTheme.accent)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
        }
    }

    // MARK: - Büyük Üçlü Özeti

    private func bigThreeSummary(_ chart: BirthChart) -> some View {
        VStack(spacing: 12) {
            Text("Büyük Üçlü")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                miniSignCard(label: "Güneş", sign: chart.sunSign, color: .orange)
                miniSignCard(label: "Ay", sign: chart.moonSign, color: AstroTheme.accentSecondary)
                miniSignCard(label: "Yükselen", sign: chart.ascendant, color: AstroTheme.accent)
            }
        }
        .glassCard()
    }

    private func miniSignCard(label: String, sign: ZodiacSign?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(sign?.glyph ?? "?")
                .font(.title2)
                .accessibilityHidden(true)
            Text(sign?.name ?? "-")
                .font(.caption.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(sign?.name ?? "bilinmiyor")")
    }

    // MARK: - Element Özeti

    private func elementSummary(_ chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Element Dengesi")
                .font(.headline)
                .foregroundStyle(.white)

            let balance = chart.elementBalance
            let total = max(balance.values.reduce(0, +), 1)

            ForEach(ZodiacSign.Element.allCases, id: \.self) { element in
                let count = balance[element] ?? 0
                let ratio = Double(count) / Double(total)

                HStack(spacing: 10) {
                    Text(element.displayName)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 50, alignment: .leading)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(elementColor(element))
                            .frame(width: geo.size.width * ratio)
                    }
                    .frame(height: 8)

                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                        .frame(width: 16, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(element.displayName): \(count) gezegen")
            }
        }
        .glassCard()
    }

    // MARK: - Yeniden Hesapla

    private var recalculateButton: some View {
        Button {
            Task { await appState.restoreSavedChart() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                Text("Haritayı Yeniden Hesapla")
            }
            .font(.caption)
            .foregroundStyle(AstroTheme.textSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AstroTheme.surface, in: .capsule)
        }
    }

    // MARK: - Boş Durum

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(AstroTheme.textTertiary)

            Text("Henüz profil oluşturulmadı")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Harita sekmesinden doğum bilgilerinizi girerek profilinizi oluşturun.")
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func elementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire: AstroTheme.fire
        case .earth: AstroTheme.earth
        case .air: AstroTheme.air
        case .water: AstroTheme.water
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .long
        return f.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.timeStyle = .short
        return f.string(from: date)
    }
}
