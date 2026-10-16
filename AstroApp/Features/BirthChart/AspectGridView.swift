import SwiftUI

/// Profesyonel astroloji yazılımlarındaki üçgen açı matrisi.
/// Tüm gezegen çiftleri arasındaki açıları kompakt grid olarak gösterir.
struct AspectGridView: View {
    let chart: BirthChart
    /// Hücreye dokununca (nil → salt görüntü)
    var onSelect: ((Aspect) -> Void)? = nil

    /// Grid'de gösterilecek noktalar
    private var points: [ChartPoint] {
        // Sadece haritada pozisyonu olan gezegenleri + ASC/MC göster
        var result: [ChartPoint] = []
        for planet in Planet.classicPlanets {
            if chart.planets.contains(where: { $0.planet == planet }) {
                result.append(.planet(planet))
            }
        }
        // Chiron ve Kuzey Düğüm
        for extra in [Planet.northNode, .chiron] {
            if chart.planets.contains(where: { $0.planet == extra }) {
                result.append(.planet(extra))
            }
        }
        // ASC ve MC (evler varsa)
        if chart.houses.contains(where: { $0.id == 1 }) {
            result.append(.ascendant)
        }
        if chart.houses.contains(where: { $0.id == 10 }) {
            result.append(.midheaven)
        }
        return result
    }

    /// Hızlı aspect lookup
    private var aspectLookup: [String: Aspect] {
        var dict: [String: Aspect] = [:]
        for aspect in chart.aspects {
            let key1 = "\(aspect.point1)_\(aspect.point2)"
            let key2 = "\(aspect.point2)_\(aspect.point1)"
            dict[key1] = aspect
            dict[key2] = aspect
        }
        return dict
    }

    var body: some View {
        let pts = points
        let lookup = aspectLookup

        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Her satır: satır 1'den başlar (ilk gezegen satır olmaz, sadece sütun başlığıdır)
                ForEach(1..<pts.count, id: \.self) { row in
                    HStack(spacing: 0) {
                        // Sol: satır gezegen glifi
                        Text(pts[row].glyph)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundStyle(AstroTheme.point(pts[row]))
                            .frame(width: 32, height: 28)

                        // Hücreler: 0..<row
                        ForEach(0..<row, id: \.self) { col in
                            let key = "\(pts[row])_\(pts[col])"
                            if let aspect = lookup[key] {
                                if let onSelect {
                                    Button { onSelect(aspect) } label: { aspectCell(aspect) }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("\(aspect.point1.name) \(aspect.type.turkishName) \(aspect.point2.name), orb \(String(format: "%.1f", aspect.orb)) derece")
                                } else {
                                    aspectCell(aspect)
                                }
                            } else {
                                emptyCell
                            }
                        }
                    }
                }

                // Alt satır: sütun başlıkları
                HStack(spacing: 0) {
                    Color.clear.frame(width: 32, height: 20) // sol boşluk
                    ForEach(0..<(pts.count - 1), id: \.self) { col in
                        Text(pts[col].glyph)
                            .font(.system(size: 11, weight: .medium, design: .serif))
                            .foregroundStyle(AstroTheme.point(pts[col]))
                            .frame(width: 32, height: 20)
                    }
                }
            }
        }
    }

    private func aspectCell(_ aspect: Aspect) -> some View {
        let bgColor = AstroTheme.nature(aspect.type.nature)

        return VStack(spacing: 0) {
            Text(aspect.type.symbol)
                .font(.system(size: 10))
                .foregroundStyle(bgColor)
            Text(String(format: "%.0f", aspect.orb))
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(width: 32, height: 28)
        .background(bgColor.opacity(0.1), in: .rect(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var emptyCell: some View {
        Color.clear
            .frame(width: 32, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.03), lineWidth: 0.5)
            )
    }
}
