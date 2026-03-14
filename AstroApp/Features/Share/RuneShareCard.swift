import SwiftUI

struct RuneShareCard: View {
    let card: RuneCard

    var body: some View {
        ShareCardTemplate(title: "RUNE FALI", subtitle: formattedDate, seed: 77) {
            // Rune
            VStack(spacing: 12) {
                Text(card.symbol)
                    .font(.system(size: 56))

                Text(card.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 260, height: 200)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            }

            // Kısa yorum özeti
            shareGlassBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Runenin Yorumu")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text(summaryText)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(4)
                        .lineLimit(6)
                }
            }
        }
    }

    private var summaryText: String {
        let cleaned = card.description
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
        return String(cleaned.prefix(300))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date.now)
    }
}
