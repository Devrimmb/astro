import SwiftUI

struct ChartWheelView: View {
    let chart: BirthChart
    let size: CGFloat

    private var outerRadius: CGFloat { size / 2 - 10 }
    private var signRingInner: CGFloat { outerRadius - 36 }
    private var houseRingInner: CGFloat { signRingInner - 70 }
    private var planetRingRadius: CGFloat { (signRingInner + houseRingInner) / 2 }
    private var innerRadius: CGFloat { houseRingInner }

    /// Ascendant derecesi — chart'ın sol tarafına (9 o'clock) hizalanır
    private var ascDegree: Double {
        chart.houses.first(where: { $0.id == 1 })?.cusp ?? 0
    }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            drawZodiacRing(context: &context, center: center)
            drawZodiacGlyphs(context: &context, center: center)
            drawHouseLines(context: &context, center: center)
            drawHouseNumbers(context: &context, center: center)
            drawPlanets(context: &context, center: center)
            drawAspectLines(context: &context, center: center)
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }

    // MARK: - Burç Halkası

    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        for sign in ZodiacSign.allCases {
            let startDeg = Double(sign.rawValue) * 30.0
            let endDeg = startDeg + 30.0

            let startAngle = chartAngle(startDeg)
            let endAngle = chartAngle(endDeg)

            var path = Path()
            path.addArc(center: center, radius: outerRadius,
                        startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addArc(center: center, radius: signRingInner,
                        startAngle: endAngle, endAngle: startAngle, clockwise: true)
            path.closeSubpath()

            let color: Color = switch sign.element {
            case .fire: .red.opacity(0.25)
            case .earth: .green.opacity(0.2)
            case .air: .yellow.opacity(0.2)
            case .water: .blue.opacity(0.25)
            }

            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(.white.opacity(0.4)), lineWidth: 0.5)
        }

        // İç ve dış çember çizgileri
        var outerCircle = Path()
        outerCircle.addEllipse(in: CGRect(
            x: center.x - outerRadius, y: center.y - outerRadius,
            width: outerRadius * 2, height: outerRadius * 2))
        context.stroke(outerCircle, with: .color(.white.opacity(0.6)), lineWidth: 1)

        var innerCircle = Path()
        innerCircle.addEllipse(in: CGRect(
            x: center.x - signRingInner, y: center.y - signRingInner,
            width: signRingInner * 2, height: signRingInner * 2))
        context.stroke(innerCircle, with: .color(.white.opacity(0.6)), lineWidth: 1)

        var houseCircle = Path()
        houseCircle.addEllipse(in: CGRect(
            x: center.x - houseRingInner, y: center.y - houseRingInner,
            width: houseRingInner * 2, height: houseRingInner * 2))
        context.stroke(houseCircle, with: .color(.white.opacity(0.4)), lineWidth: 0.5)
    }

    // MARK: - Burç Sembolleri

    private func drawZodiacGlyphs(context: inout GraphicsContext, center: CGPoint) {
        let glyphRadius = (outerRadius + signRingInner) / 2

        for sign in ZodiacSign.allCases {
            let midDeg = Double(sign.rawValue) * 30.0 + 15.0
            let angle = chartAngle(midDeg)
            let point = pointOnCircle(center: center, radius: glyphRadius, angle: angle)

            let text = Text(sign.glyph).font(.system(size: size * 0.045)).foregroundColor(.white)
            let resolved = context.resolve(text)
            let textSize = resolved.measure(in: CGSize(width: 40, height: 40))
            context.draw(resolved, at: CGPoint(
                x: point.x - textSize.width / 2,
                y: point.y - textSize.height / 2
            ), anchor: .topLeading)
        }
    }

    // MARK: - Ev Çizgileri

    private func drawHouseLines(context: inout GraphicsContext, center: CGPoint) {
        for house in chart.houses {
            let angle = chartAngle(house.cusp)
            let outerPoint = pointOnCircle(center: center, radius: signRingInner, angle: angle)
            let innerPoint = pointOnCircle(center: center, radius: houseRingInner, angle: angle)

            var path = Path()
            path.move(to: outerPoint)
            path.addLine(to: innerPoint)

            let lineWidth: CGFloat = (house.id == 1 || house.id == 4 || house.id == 7 || house.id == 10) ? 1.5 : 0.5
            let opacity: Double = (house.id == 1 || house.id == 4 || house.id == 7 || house.id == 10) ? 0.8 : 0.4
            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: lineWidth)
        }

        // ASC ve MC etiketleri
        let ascAngle = chartAngle(chart.houses[0].cusp)
        let ascLabelPoint = pointOnCircle(center: center, radius: signRingInner + 4, angle: ascAngle)
        let ascText = Text("ASC").font(.system(size: size * 0.028, weight: .bold)).foregroundColor(.orange)
        context.draw(context.resolve(ascText), at: ascLabelPoint, anchor: .trailing)

        if chart.houses.count >= 10 {
            let mcAngle = chartAngle(chart.houses[9].cusp)
            let mcLabelPoint = pointOnCircle(center: center, radius: signRingInner + 4, angle: mcAngle)
            let mcText = Text("MC").font(.system(size: size * 0.028, weight: .bold)).foregroundColor(.orange)
            context.draw(context.resolve(mcText), at: mcLabelPoint, anchor: .bottom)
        }
    }

    // MARK: - Ev Numaraları

    private func drawHouseNumbers(context: inout GraphicsContext, center: CGPoint) {
        for i in 0..<chart.houses.count {
            let currentCusp = chart.houses[i].cusp
            let nextCusp = i + 1 < chart.houses.count ? chart.houses[i + 1].cusp : chart.houses[0].cusp + 360
            var midDeg = (currentCusp + nextCusp) / 2
            if nextCusp < currentCusp { midDeg = (currentCusp + nextCusp + 360) / 2 }

            let angle = chartAngle(midDeg)
            let numRadius = houseRingInner + 12
            let point = pointOnCircle(center: center, radius: numRadius, angle: angle)

            let text = Text("\(chart.houses[i].id)")
                .font(.system(size: size * 0.025))
                .foregroundColor(.white.opacity(0.5))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }
    }

    // MARK: - Gezegen Sembolleri

    private func drawPlanets(context: inout GraphicsContext, center: CGPoint) {
        // Gezegen pozisyonlarını topla ve çakışmaları ayır
        var placements: [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)] = []
        for pos in chart.planets {
            placements.append((pos.planet, pos.longitude, pos.longitude))
        }
        resolvePlanetCollisions(&placements)

        for placement in placements {
            let angle = chartAngle(placement.displayDeg)
            let point = pointOnCircle(center: center, radius: planetRingRadius, angle: angle)

            let glyph = planetGlyph(placement.planet)
            let text = Text(glyph)
                .font(.system(size: size * 0.038))
                .foregroundColor(planetColor(placement.planet))
            context.draw(context.resolve(text), at: point, anchor: .center)

            // Gerçek pozisyona ince çizgi
            let realAngle = chartAngle(placement.degree)
            let tickOuter = pointOnCircle(center: center, radius: signRingInner - 2, angle: realAngle)
            let tickInner = pointOnCircle(center: center, radius: signRingInner - 8, angle: realAngle)
            var tickPath = Path()
            tickPath.move(to: tickOuter)
            tickPath.addLine(to: tickInner)
            context.stroke(tickPath, with: .color(planetColor(placement.planet).opacity(0.6)), lineWidth: 0.8)
        }
    }

    // MARK: - Açı Çizgileri

    private func drawAspectLines(context: inout GraphicsContext, center: CGPoint) {
        let aspectRadius = houseRingInner - 2

        for aspect in chart.aspects {
            // ChartPoint'ten longitude çöz
            guard let lon1 = longitude(for: aspect.point1),
                  let lon2 = longitude(for: aspect.point2) else { continue }

            let angle1 = chartAngle(lon1)
            let angle2 = chartAngle(lon2)
            let point1 = pointOnCircle(center: center, radius: aspectRadius, angle: angle1)
            let point2 = pointOnCircle(center: center, radius: aspectRadius, angle: angle2)

            var path = Path()
            path.move(to: point1)
            path.addLine(to: point2)

            let color: Color = switch aspect.type.nature {
            case .harmonik: .green
            case .zorlayici: .red
            case .notr: .blue
            }

            let lineWidth: CGFloat = aspect.type.isMajor ? (aspect.type == .conjunction ? 1.0 : 0.6) : 0.4
            let dash: [CGFloat] = switch aspect.type {
            case .sextile: [4, 3]
            case .semiSextile, .quincunx: [2, 2]
            case .semiSquare, .sesquiquadrate: [1, 2]
            default: []
            }

            let style = StrokeStyle(lineWidth: lineWidth, dash: dash)
            context.stroke(path, with: .color(color.opacity(aspect.type.isMajor ? 0.4 : 0.25)), style: style)
        }
    }

    /// ChartPoint'ten longitude değerini çözer
    private func longitude(for point: ChartPoint) -> Double? {
        switch point {
        case .planet(let p):
            return chart.planets.first(where: { $0.planet == p })?.longitude
        case .ascendant:
            return chart.houses.first(where: { $0.id == 1 })?.cusp
        case .midheaven:
            return chart.houses.first(where: { $0.id == 10 })?.cusp
        }
    }

    // MARK: - Yardımcılar

    /// Ekliptik derece → Canvas açısı. Ascendant sol tarafa (180°) hizalanır.
    private func chartAngle(_ eclipticDegree: Double) -> Angle {
        Angle(degrees: -(eclipticDegree - ascDegree) + 180)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let rad = angle.radians
        return CGPoint(
            x: center.x + radius * CGFloat(Foundation.cos(rad)),
            y: center.y - radius * CGFloat(Foundation.sin(rad))
        )
    }

    private func planetGlyph(_ planet: AstroApp.Planet) -> String {
        switch planet {
        case .sun: "☉"
        case .moon: "☽"
        case .mercury: "☿"
        case .venus: "♀"
        case .mars: "♂"
        case .jupiter: "♃"
        case .saturn: "♄"
        case .uranus: "♅"
        case .neptune: "♆"
        case .pluto: "♇"
        case .northNode: "☊"
        case .chiron: "⚷"
        case .lilith: "⚸"
        case .partOfFortune: "⊕"
        case .ceres: "⚳"
        case .pallas: "⚴"
        case .juno: "⚵"
        case .vesta: "⚶"
        }
    }

    private func planetColor(_ planet: AstroApp.Planet) -> Color {
        switch planet {
        case .sun: .orange
        case .moon: .white
        case .mercury: .cyan
        case .venus: .pink
        case .mars: .red
        case .jupiter: .purple
        case .saturn: .brown
        case .uranus: .teal
        case .neptune: .indigo
        case .pluto: .gray
        case .northNode: .mint
        case .chiron: .yellow
        case .lilith: Color(red: 0.3, green: 0, blue: 0.3)
        case .partOfFortune: .green
        case .ceres: Color(red: 0.6, green: 0.4, blue: 0.2)
        case .pallas: Color(red: 0.5, green: 0.7, blue: 0.9)
        case .juno: Color(red: 0.8, green: 0.4, blue: 0.6)
        case .vesta: Color(red: 0.9, green: 0.5, blue: 0.2)
        }
    }

    /// Yakın gezegenlerin çakışmasını çözer (minimum 8° arayla yerleştirir)
    private func resolvePlanetCollisions(_ placements: inout [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)]) {
        let minGap = 8.0
        placements.sort { $0.degree < $1.degree }

        for pass in 0..<5 {
            var changed = false
            for i in 0..<placements.count {
                let j = (i + 1) % placements.count
                var diff = placements[j].displayDeg - placements[i].displayDeg
                if diff < 0 { diff += 360 }
                if diff < minGap && diff > 0 {
                    placements[i].displayDeg -= (minGap - diff) / 2
                    placements[j].displayDeg += (minGap - diff) / 2
                    if placements[i].displayDeg < 0 { placements[i].displayDeg += 360 }
                    if placements[j].displayDeg >= 360 { placements[j].displayDeg -= 360 }
                    changed = true
                }
            }
            if !changed { break }
            _ = pass
        }
    }
}
