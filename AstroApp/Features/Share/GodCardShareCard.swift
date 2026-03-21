import SwiftUI

struct GodCardShareCard: View {
    let card: GodCard

    var body: some View {
        ShareCardTemplate(title: "TANRI KARTLARI", subtitle: formattedDate, seed: 99) {
            // Kart
            VStack(spacing: 0) {
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180)

                Text(card.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .frame(width: 180)
                    .background(Color.white.opacity(0.06))
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }

            // Kısa yorum özeti
            shareGlassBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tanrının Mesajı")
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
