import SwiftUI

struct SolarReturnShareCard: View {
    let personName: String
    let solarReturn: SolarReturn

    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)
    private let lightBlue = Color(red: 0.35, green: 0.78, blue: 0.98)

    var body: some View {
        ShareCardTemplate(title: "GÜNEŞ DÖNÜŞÜ", subtitle: personName, seed: 66) {
            // Yıl ve tarih
            VStack(spacing: 8) {
                Text(String(solarReturn.year))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(purple)
                Text(solarReturn.dateText)
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Harita
            ChartWheelView(chart: solarReturn.chart, size: 580)
                .padding(.vertical, 12)

            // Büyük Üçlü
            shareGlassBox {
                VStack(spacing: 20) {
                    Text("Yıllık Büyük Üçlü")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 32) {
                        bigThreeItem(
                            icon: "arrow.up.circle.fill",
                            label: "YÜKSELEN",
                            sign: solarReturn.returnAscendant,
                            color: purple
                        )
                        bigThreeItem(
                            icon: "moon.fill",
                            label: "AY",
                            sign: solarReturn.returnMoonSign,
                            color: lightBlue
                        )
                        bigThreeItem(
                            icon: "sun.max.fill",
                            label: "GÜNEŞ",
                            sign: solarReturn.chart.sunSign,
                            color: AstroTheme.planet(.sun)
                        )
                    }
                }
            }

            // Gezegen konumları
            shareGlassBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gezegen Konumları")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    ForEach(solarReturn.chart.planets, id: \.planet) { pos in
                        HStack(spacing: 10) {
                            Text(pos.planet.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 110, alignment: .leading)
                            Text(pos.sign.glyph)
                                .font(.system(size: 18))
                            Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(pos.house). ev")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                            if pos.isRetrograde {
                                Text("℞")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AstroTheme.zorlayici)
                            }
                        }
                    }
                }
            }
        }
    }

    private func bigThreeItem(icon: String, label: String, sign: ZodiacSign?, color: Color) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
            if let sign {
                Text(sign.glyph)
                    .font(.system(size: 40))
                Text(sign.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
