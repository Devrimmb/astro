import SwiftUI

struct CompositeShareCard: View {
    let person1Name: String
    let person2Name: String
    let composite: CompositeChart

    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)
    private let lightBlue = Color(red: 0.35, green: 0.78, blue: 0.98)

    var body: some View {
        ShareCardTemplate(title: "COMPOSITE HARİTA", subtitle: "", seed: 88) {
            // İsimler
            HStack(spacing: 16) {
                Text(person1Name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(purple)
                Image(systemName: "arrow.triangle.merge")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.4))
                Text(person2Name)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(lightBlue)
            }

            // Harita
            ChartWheelView(chart: composite.asBirthChart, size: 580)
                .padding(.vertical, 12)

            // Büyük Üçlü
            shareGlassBox {
                VStack(spacing: 20) {
                    Text("Composite Büyük Üçlü")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 32) {
                        bigThreeItem(label: "GÜNEŞ", sign: composite.sunSign, color: .orange)
                        bigThreeItem(label: "AY", sign: composite.moonSign, color: lightBlue)
                        bigThreeItem(label: "YÜKSELEN", sign: composite.ascendant, color: purple)
                    }
                }
            }

            // Gezegen konumları
            shareGlassBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gezegen Konumları")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    ForEach(composite.planets, id: \.planet) { pos in
                        HStack(spacing: 10) {
                            Text(pos.planet.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 100, alignment: .leading)
                            Text(pos.sign.glyph)
                                .font(.system(size: 18))
                            Text("\(pos.sign.name) \(String(format: "%.1f", pos.degree))°")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(pos.house). ev")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
        }
    }

    private func bigThreeItem(label: String, sign: ZodiacSign?, color: Color) -> some View {
        VStack(spacing: 10) {
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
