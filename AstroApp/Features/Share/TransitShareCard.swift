import SwiftUI

struct TransitShareCard: View {
    let personName: String
    let date: Date
    let report: TransitReport

    private let purple = Color(red: 0.56, green: 0.44, blue: 1.0)
    private let lightBlue = Color(red: 0.35, green: 0.78, blue: 0.98)

    var body: some View {
        ShareCardTemplate(title: "TRANSİTLER", subtitle: personName, seed: 55) {
            // Tarih
            Text(formattedDate)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.5))

            // Gezegen konumları
            shareGlassBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Gezegen Konumları")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(report.transitPositions, id: \.planet) { pos in
                            HStack(spacing: 8) {
                                Text(pos.planet.glyph)
                                    .font(.system(size: 20))
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pos.planet.name)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.5))
                                    HStack(spacing: 4) {
                                        Text(pos.sign.glyph)
                                            .font(.system(size: 16))
                                        Text("\(pos.sign.name) \(String(format: "%.0f", pos.degree))°")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                        if pos.isRetrograde {
                                            Text("℞")
                                                .font(.system(size: 14))
                                                .foregroundStyle(AstroTheme.zorlayici)
                                        }
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }

            // Önemli transitler
            if !report.significantTransits.isEmpty {
                shareGlassBox {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Önemli Transitler")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        ForEach(report.significantTransits.prefix(6)) { aspect in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(aspectNatureColor(aspect.type))
                                    .frame(width: 10, height: 10)
                                Text("T.\(aspect.transitPlanet.name)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(aspect.type.symbol)
                                    .font(.system(size: 16))
                                    .foregroundStyle(aspectNatureColor(aspect.type))
                                Text("N.\(aspect.natalPlanet.name)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.1f°", aspect.orb))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }

            // Özet
            HStack(spacing: 32) {
                statItem(
                    value: "\(report.harmoniousTransits.count)",
                    label: "Uyumlu",
                    color: Color(red: 0.30, green: 0.85, blue: 0.65)
                )
                statItem(
                    value: "\(report.challengingTransits.count)",
                    label: "Zorlayıcı",
                    color: Color(red: 1.0, green: 0.40, blue: 0.45)
                )
                statItem(
                    value: "\(report.aspects.count)",
                    label: "Toplam",
                    color: purple
                )
            }
            .padding(.top, 8)
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func aspectNatureColor(_ type: AspectType) -> Color {
        switch type.nature {
        case .harmonik: Color(red: 0.30, green: 0.85, blue: 0.65)
        case .zorlayici: Color(red: 1.0, green: 0.40, blue: 0.45)
        case .notr: purple
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
