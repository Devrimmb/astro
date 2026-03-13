import SwiftUI

struct TarotShareCard: View {
    let card: TarotCard
    let category: TarotCategory

    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)

    var body: some View {
        ShareCardTemplate(title: "TAROT FALI", subtitle: formattedDate, seed: 44) {
            // Kategori
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                Text(category.rawValue)
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(purple)

            // Kart
            VStack(spacing: 12) {
                Text(card.image)
                    .font(.system(size: 52))

                Text(card.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 260, height: 220)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
            }

            // Kısa yorum özeti (ilk 200 karakter)
            shareGlassBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kartın Yorumu")
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

    /// Paylaşım kartı için markdown'dan temizlenmiş kısa özet
    private var summaryText: String {
        let raw = card.descriptions.text(for: category)
        // Basit markdown temizliği
        let cleaned = raw
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
        let trimmed = String(cleaned.prefix(300))
        return trimmed
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date.now)
    }
}
