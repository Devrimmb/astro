import SwiftUI

struct TarotShareCard: View {
    let drawnCards: [DrawnCard]

    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)
    private let lightBlue = Color(red: 0.35, green: 0.78, blue: 0.98)
    private let red = Color(red: 1.0, green: 0.40, blue: 0.45)

    var body: some View {
        ShareCardTemplate(title: "TAROT FALI", subtitle: formattedDate, seed: 44) {
            // Kartlar
            HStack(spacing: 24) {
                ForEach(drawnCards) { drawn in
                    cardItem(drawn)
                }
            }
            .padding(.horizontal, 40)

            // Yorumlar
            shareGlassBox {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Kartların Mesajı")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    ForEach(drawnCards) { drawn in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(drawn.position.rawValue.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(purple)
                                    .tracking(1)
                                Text(drawn.card.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                if drawn.isReversed {
                                    Text("(Ters)")
                                        .font(.system(size: 14))
                                        .foregroundStyle(red)
                                }
                            }
                            Text(drawn.interpretation)
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(4)
                        }

                        if drawn.id != drawnCards.last?.id {
                            Rectangle()
                                .fill(.white.opacity(0.06))
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
    }

    private func cardItem(_ drawn: DrawnCard) -> some View {
        VStack(spacing: 12) {
            Text(drawn.position.rawValue)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1)
                .textCase(.uppercase)

            VStack(spacing: 10) {
                Text(drawn.card.image)
                    .font(.system(size: 52))

                Text(drawn.card.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if drawn.isReversed {
                    Text("Ters")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(red.opacity(0.15), in: .capsule)
                }
            }
            .frame(width: 260, height: 280)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date.now)
    }
}
