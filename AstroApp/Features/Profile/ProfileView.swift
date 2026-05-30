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
                            gamificationCard
                            dailyTasksCard
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

    // MARK: - Oyunlaştırma Kartı

    private var gamificationCard: some View {
        let gm = appState.gamification

        return VStack(spacing: 16) {
            // Seviye başlığı
            HStack(spacing: 10) {
                Image(systemName: gm.currentLevel.icon)
                    .font(.title)
                    .foregroundStyle(AstroTheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Seviye \(gm.currentLevel.rank)")
                            .font(.caption)
                            .foregroundStyle(AstroTheme.textTertiary)
                        InfoTip(
                            title: "Seviye Sistemi",
                            message: "Yıldız kazandıkça seviyen yükselir. 10 seviye var: Yeni Ay'dan Evren'e! Her gün giriş yaparak serin artar ve bonus çarpanın yükselir."
                        )
                    }
                    Text(gm.currentLevel.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("\(gm.totalStars)")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    Text("yıldız")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                }
            }

            // İlerleme çubuğu
            if let next = gm.nextLevel {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AstroTheme.accent, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * gm.levelProgress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text(gm.currentLevel.name)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.textTertiary)
                        Spacer()
                        Text(next.name)
                            .font(.caption2)
                            .foregroundStyle(AstroTheme.accent)
                    }
                }
            }

            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 1)

            // İstatistikler
            HStack(spacing: 0) {
                statItem(icon: "flame.fill", value: "\(gm.currentStreak)", label: "Seri", color: .orange)
                statItem(icon: "trophy.fill", value: "\(gm.longestStreak)", label: "En Uzun", color: .yellow)
                statItem(icon: "arrow.up.circle.fill", value: "x\(String(format: "%.1f", gm.streakMultiplier))", label: "Bonus", color: .green)
            }
        }
        .glassCard()
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Günlük Görevler

    private var dailyTasksCard: some View {
        let gm = appState.gamification

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundStyle(AstroTheme.accent)
                Text("Günlük Görevler")
                    .font(.headline)
                    .foregroundStyle(.white)
                InfoTip(
                    title: "Günlük Görevler",
                    message: "Her gün 5 basit görevi tamamlayarak yıldız kazan! Görevler gece yarısı sıfırlanır. Serin devam ettikçe kazandığın yıldızlara bonus eklenir."
                )
                Spacer()
                Text("\(gm.completedTaskCount)/\(gm.totalTaskCount)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(AstroTheme.accent)
            }

            // İlerleme çubuğu
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (gm.totalTaskCount > 0 ? Double(gm.completedTaskCount) / Double(gm.totalTaskCount) : 0))
                }
            }
            .frame(height: 6)

            ForEach(gm.dailyTasks) { task in
                HStack(spacing: 12) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.isCompleted ? .green : AstroTheme.textTertiary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(task.isCompleted ? AstroTheme.textTertiary : .white)
                            .strikethrough(task.isCompleted, color: AstroTheme.textTertiary)
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow.opacity(task.isCompleted ? 0.4 : 1))
                            Text("+\(task.stars)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(task.isCompleted ? AstroTheme.textTertiary : .yellow)
                        }
                    }

                    Spacer()

                    Image(systemName: task.icon)
                        .font(.caption)
                        .foregroundStyle(task.isCompleted ? AstroTheme.textTertiary : AstroTheme.accent)
                }
                .padding(.vertical, 4)

                if task.id != gm.dailyTasks.last?.id {
                    Divider().overlay(AstroTheme.cardBorder)
                }
            }
        }
        .glassCard()
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
                let score = balance[element] ?? 0
                let ratio = score / total

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

                    Text("%\(Int((ratio * 100).rounded()))")
                        .font(.caption2)
                        .foregroundStyle(AstroTheme.textTertiary)
                        .frame(width: 28, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(element.displayName): \(score) puan")
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
