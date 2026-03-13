import SwiftUI

/// Doğum haritasını paylaşılabilir bir kart olarak render eden view.
/// ImageRenderer ile PNG'ye çevrilir, ShareLink ile paylaşılır.
struct ChartShareCard: View {
    let chart: BirthChart
    let ownerName: String

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Arka plan
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.10, green: 0.06, blue: 0.22),
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Yıldız efekti
            starsOverlay

            VStack(spacing: 40) {
                // Üst başlık
                VStack(spacing: 12) {
                    Text("✦ DOĞUM HARİTASI ✦")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(4)

                    if !ownerName.isEmpty {
                        Text(ownerName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color(red: 0.56, green: 0.44, blue: 1.0))
                    }

                    Text(formattedBirthDate)
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 80)

                // Harita çizimi
                ChartWheelView(chart: chart, size: 680)
                    .padding(.vertical, 20)

                // Büyük Üçlü
                bigThreeSection

                Spacer()

                // Alt bilgi
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(Color(red: 0.56, green: 0.44, blue: 1.0))
                    Text("AstroApp")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Büyük Üçlü

    private var bigThreeSection: some View {
        HStack(spacing: 48) {
            bigThreeItem(
                label: "GÜNEŞ",
                sign: chart.sunSign,
                icon: "sun.max.fill",
                color: .orange
            )
            bigThreeItem(
                label: "AY",
                sign: chart.moonSign,
                icon: "moon.fill",
                color: Color(red: 0.35, green: 0.78, blue: 0.98)
            )
            bigThreeItem(
                label: "YÜKSELEN",
                sign: chart.ascendant,
                icon: "arrow.up.circle.fill",
                color: Color(red: 0.56, green: 0.44, blue: 1.0)
            )
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.horizontal, 40)
    }

    private func bigThreeItem(label: String, sign: ZodiacSign?, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
            if let sign {
                Text(sign.glyph)
                    .font(.system(size: 44))
                Text(sign.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Yardımcılar

    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: chart.birthDate)
    }

    private var starsOverlay: some View {
        Canvas { context, size in
            var rng = StableShareRNG(seed: 77)
            for _ in 0..<120 {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let radius = CGFloat.random(in: 0.5...2.0, using: &rng)
                let opacity = Double.random(in: 0.1...0.4, using: &rng)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(opacity)))
            }
        }
    }
}

// MARK: - Synastry Paylaşım Kartı

struct SynastryShareCard: View {
    let person1Name: String
    let person2Name: String
    let discopoloScore: Int
    let discopoloDescription: String
    let aspectScore: Int
    let emotionalScore: Int
    let communicationScore: Int
    let passionScore: Int
    let stabilityScore: Int

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.15, green: 0.04, blue: 0.18),
                    Color(red: 0.04, green: 0.05, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            starsOverlay

            VStack(spacing: 44) {
                // Başlık
                VStack(spacing: 12) {
                    Text("✦ UYUM ANALİZİ ✦")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(4)

                    HStack(spacing: 16) {
                        Text(person1Name)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color(red: 0.56, green: 0.44, blue: 1.0))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.45))
                        Text(person2Name)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color(red: 0.35, green: 0.78, blue: 0.98))
                    }
                }
                .padding(.top, 100)

                // Discepolo Skoru
                VStack(spacing: 16) {
                    Text("Ciro Discepolo Skoru")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("\(discopoloScore)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(discopoloColor)

                    Text(discopoloDescription)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(discopoloColor)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 60)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 40)

                // Aspect bazlı skor dairesi
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 12)
                        .frame(width: 180, height: 180)
                    Circle()
                        .trim(from: 0, to: Double(aspectScore) / 100)
                        .stroke(aspectScoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(aspectScore)")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                        Text("/ 100")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                // Kategori çubukları
                VStack(spacing: 20) {
                    categoryBar(icon: "heart.fill", title: "Duygusal", score: emotionalScore, color: Color(red: 1.0, green: 0.40, blue: 0.45))
                    categoryBar(icon: "bubble.left.fill", title: "İletişim", score: communicationScore, color: Color(red: 0.56, green: 0.44, blue: 1.0))
                    categoryBar(icon: "flame.fill", title: "Tutku", score: passionScore, color: .orange)
                    categoryBar(icon: "shield.fill", title: "Kararlılık", score: stabilityScore, color: Color(red: 0.30, green: 0.85, blue: 0.65))
                }
                .padding(.horizontal, 80)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .foregroundStyle(Color(red: 0.56, green: 0.44, blue: 1.0))
                    Text("AstroApp")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    private func categoryBar(icon: String, title: String, score: Int, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 110, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * Double(score) / 100)
                }
            }
            .frame(height: 14)

            Text("\(score)")
                .font(.system(size: 20, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var discopoloColor: Color {
        switch discopoloScore {
        case 20...: Color(red: 0.30, green: 0.85, blue: 0.65)
        case 15..<20: Color(red: 0.35, green: 0.78, blue: 0.98)
        case 10..<15: Color(red: 0.56, green: 0.44, blue: 1.0)
        case 5..<10: .orange
        default: Color.white.opacity(0.55)
        }
    }

    private var aspectScoreColor: Color {
        switch aspectScore {
        case 70...100: Color(red: 0.30, green: 0.85, blue: 0.65)
        case 50..<70: Color(red: 0.56, green: 0.44, blue: 1.0)
        case 30..<50: .orange
        default: Color(red: 1.0, green: 0.40, blue: 0.45)
        }
    }

    private var starsOverlay: some View {
        Canvas { context, size in
            var rng = StableShareRNG(seed: 99)
            for _ in 0..<120 {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let radius = CGFloat.random(in: 0.5...2.0, using: &rng)
                let opacity = Double.random(in: 0.1...0.4, using: &rng)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(opacity)))
            }
        }
    }
}

// MARK: - Stable RNG (paylaşım kartları için)

struct StableShareRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
