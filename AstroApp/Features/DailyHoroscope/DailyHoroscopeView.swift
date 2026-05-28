import SwiftUI

struct DailyHoroscopeView: View {
    @Environment(AppState.self) private var appState
    @Environment(EntitlementManager.self) private var entitlements
    @State private var selectedSign: ZodiacSign?
    @State private var horoscope: DailyHoroscope?
    @State private var isUnlockedByAd = false
    @State private var showAdGate = false

    /// Kullanıcının kendi güneş burcu
    private var userSign: ZodiacSign? {
        appState.currentChart?.sunSign
            ?? appState.birthDataStore.savedData.map { ZodiacSign.from(birthDate: $0.birthDate) }
    }

    /// Seçili burç kendi burcuysa veya Pro ise göster, değilse reklam gate
    private var canViewSelected: Bool {
        entitlements.hasNatalChart || isUnlockedByAd || selectedSign == userSign
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SubtleStarsBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        signSelector
                        if !canViewSelected {
                            dailyAdGate
                        } else if let horoscope {
                            horoscopeCard(horoscope)
                            moodCard(horoscope)
                            adviceCard(horoscope)
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Günlük Yorum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if selectedSign == nil {
                    selectedSign = appState.currentChart?.sunSign ?? .aries
                }
                generateHoroscope()
            }
            .onChange(of: selectedSign) {
                isUnlockedByAd = false
                generateHoroscope()
            }
        }
    }

    // MARK: - Burç Seçici

    private var signSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ZodiacSign.allCases, id: \.self) { sign in
                    Button {
                        selectedSign = sign
                    } label: {
                        VStack(spacing: 4) {
                            Text(sign.glyph)
                                .font(.title3)
                                .accessibilityHidden(true)
                            Text(sign.name)
                                .font(.caption2)
                        }
                        .foregroundStyle(selectedSign == sign ? .white : AstroTheme.textSecondary)
                        .frame(width: 56, height: 56)
                        .background(
                            selectedSign == sign
                                ? AnyShapeStyle(AstroTheme.accentGradient.opacity(0.5))
                                : AnyShapeStyle(AstroTheme.surface),
                            in: .rect(cornerRadius: 14)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedSign == sign ? AstroTheme.accent.opacity(0.5) : .clear, lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("\(sign.name) burcu")
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Reklam Kapısı (Diğer Burçlar)

    private var dailyAdGate: some View {
        VStack(spacing: 20) {
            if let sign = selectedSign {
                Text(sign.glyph)
                    .font(.system(size: 48))

                VStack(spacing: 8) {
                    Text("\(sign.name) Yorumu")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Diğer burçların günlük yorumunu okumak için reklam izle veya Pro'ya geç.")
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            AdGateView(
                title: "Yorumu Aç",
                description: "Kısa bir reklam izleyerek bu burcun günlük yorumunu oku."
            ) {
                isUnlockedByAd = true
                generateHoroscope()
            }
        }
    }

    // MARK: - Günlük Yorum Kartı

    private func horoscopeCard(_ h: DailyHoroscope) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(h.sign.glyph)
                    .font(.largeTitle)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(h.sign.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(h.dateText)
                        .font(.caption)
                        .foregroundStyle(AstroTheme.textSecondary)
                }
                Spacer()
                starRating(h.overallRating)
            }

            Text(h.generalText)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
                .lineSpacing(4)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mood Kartı

    private func moodCard(_ h: DailyHoroscope) -> some View {
        HStack(spacing: 0) {
            moodItem(title: "Aşk", rating: h.loveRating, icon: "heart.fill", color: AstroTheme.zorlayici)
            moodItem(title: "Kariyer", rating: h.careerRating, icon: "briefcase.fill", color: AstroTheme.accent)
            moodItem(title: "Sağlık", rating: h.healthRating, icon: "leaf.fill", color: AstroTheme.harmonik)
            moodItem(title: "Şans", rating: h.luckRating, icon: "star.fill", color: .orange)
        }
        .glassCard()
    }

    private func moodItem(title: String, rating: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AstroTheme.textSecondary)
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < rating ? color : AstroTheme.surface)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): 5 üzerinden \(rating)")
    }

    // MARK: - Tavsiye Kartı

    private func adviceCard(_ h: DailyHoroscope) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Günün Tavsiyesi")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(h.advice)
                .font(.caption)
                .foregroundStyle(AstroTheme.textSecondary)
                .lineSpacing(3)

            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.accent)
                Text("Şanslı renk: \(h.luckyColor)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
                Spacer()
                Text("Şanslı sayı: \(h.luckyNumber)")
                    .font(.caption2)
                    .foregroundStyle(AstroTheme.textTertiary)
            }
        }
        .glassCard()
    }

    // MARK: - Yıldız Rating

    private func starRating(_ rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i < rating ? .orange : AstroTheme.textTertiary)
            }
        }
        .accessibilityLabel("Genel: 5 üzerinden \(rating)")
    }

    // MARK: - Generate

    private func generateHoroscope() {
        guard let sign = selectedSign else { return }
        guard canViewSelected else {
            horoscope = nil
            return
        }
        horoscope = DailyHoroscopeGenerator.generate(for: sign, date: .now)
    }
}
