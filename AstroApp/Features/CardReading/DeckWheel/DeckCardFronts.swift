import SwiftUI

// Seçilen kartın ön yüzleri. Üç kalıp: dikey görsel (tarot, katina),
// kare görsel + ad bandı (tanrı kartı), sembol + ad (rün).

/// 400×700 dikey görsel; altta ad şeridi.
struct DeckPortraitFront: View {
    let imageName: String
    let name: String
    let size: CGSize
    var tint: Color = AstroTheme.accent

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
        ZStack(alignment: .bottom) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()

            LinearGradient(colors: [.clear, AstroTheme.background.opacity(0.92)],
                           startPoint: .init(x: 0.5, y: 0.55), endPoint: .bottom)

            Text(name)
                .font(.system(size: size.width * 0.105, weight: .semibold, design: .serif))
                .foregroundStyle(AstroTheme.gold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, size.width * 0.08)
                .padding(.bottom, size.height * 0.05)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(AstroTheme.gold.opacity(0.85), lineWidth: max(1, size.width * 0.014)))
        .shadow(color: tint.opacity(0.35), radius: 18, y: 8)
    }
}

/// Kare görsel üstte, altta koyu ad bandı.
struct DeckSquareFront: View {
    let imageName: String
    let name: String
    let size: CGSize
    var tint: Color = AstroTheme.accent

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.width)
                .clipped()

            Text(name)
                .font(.system(size: size.width * 0.1, weight: .semibold, design: .serif))
                .foregroundStyle(AstroTheme.gold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, size.width * 0.08)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AstroTheme.backgroundMid)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(AstroTheme.gold.opacity(0.85), lineWidth: max(1, size.width * 0.014)))
        .shadow(color: tint.opacity(0.35), radius: 18, y: 8)
    }
}

/// Büyük sembol + ad; görseli olmayan desteler için (rün).
struct DeckSymbolFront: View {
    let symbol: String
    let name: String
    let size: CGSize
    var tint: Color = AstroTheme.accent
    var colors: [Color] = [AstroTheme.backgroundMid, AstroTheme.background]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size.width * 0.05, style: .continuous)
                .strokeBorder(AstroTheme.gold.opacity(0.45), lineWidth: 1)
                .padding(size.width * 0.06)

            VStack(spacing: size.height * 0.06) {
                Text(symbol)
                    .font(.system(size: size.width * 0.42, design: .serif))
                    .foregroundStyle(AstroTheme.gold)
                    .shadow(color: tint.opacity(0.7), radius: size.width * 0.06)
                Text(name)
                    .font(.system(size: size.width * 0.11, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, size.width * 0.1)
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(shape.strokeBorder(AstroTheme.gold.opacity(0.85), lineWidth: max(1, size.width * 0.014)))
        .shadow(color: tint.opacity(0.35), radius: 18, y: 8)
    }
}
