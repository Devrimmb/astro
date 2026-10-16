import SwiftUI

/// Synastry için bi-wheel: iç halka = chart1, dış halka = chart2.
/// Ortak aspectler merkezdeki renkli çizgilerle gösterilir.
struct SynastryBiWheelView: View {
    let chart1: BirthChart
    let chart2: BirthChart
    let crossAspects: [SynastryAspect]
    let size: CGFloat

    // Halka yarıçapları
    private var outerRadius: CGFloat      { size / 2 - 8 }
    private var signRingInner: CGFloat    { outerRadius - 32 }
    private var separatorRing: CGFloat    { signRingInner - 36 }
    private var p2PlanetRing: CGFloat     { (signRingInner + separatorRing) / 2 }
    private var houseRingInner: CGFloat   { separatorRing - 36 }
    private var p1PlanetRing: CGFloat     { (separatorRing + houseRingInner) / 2 }
    private var aspectRadius: CGFloat     { houseRingInner - 3 }

    // Chart1'in ASC'si referans açısını belirler
    private var ascDegree: Double {
        chart1.houses.first(where: { $0.id == 1 })?.cusp ?? 0
    }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            drawZodiacRing(context: &context, center: center)
            drawZodiacGlyphs(context: &context, center: center)
            drawSeparatorRing(context: &context, center: center)
            drawHouseLines(context: &context, center: center)
            drawInnerCircle(context: &context, center: center)
            drawCrossAspects(context: &context, center: center)
            drawPlanets2(context: &context, center: center)
            drawPlanets1(context: &context, center: center)
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }

    // MARK: - Burç Halkası

    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        for sign in ZodiacSign.allCases {
            let startDeg = Double(sign.rawValue) * 30.0
            let endDeg   = startDeg + 30.0
            let startAngle = chartAngle(startDeg)
            let endAngle   = chartAngle(endDeg)

            let path = WheelGeometry.ringSegment(center: center, innerRadius: signRingInner, outerRadius: outerRadius,
                                                 startAngle: startAngle, endAngle: endAngle)

            let color = AstroTheme.element(sign.element).opacity(0.12)
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.5)
        }

        for r in [outerRadius, signRingInner] {
            var circle = Path()
            circle.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            context.stroke(circle, with: .color(.white.opacity(0.2)), lineWidth: 0.8)
        }
    }

    // MARK: - Burç Sembolleri

    private func drawZodiacGlyphs(context: inout GraphicsContext, center: CGPoint) {
        let glyphRadius = (outerRadius + signRingInner) / 2
        for sign in ZodiacSign.allCases {
            let midDeg = Double(sign.rawValue) * 30.0 + 15.0
            let angle  = chartAngle(midDeg)
            let point  = pointOnCircle(center: center, radius: glyphRadius, angle: angle)
            let text   = Text(sign.glyph)
                .font(.system(size: size * 0.04, design: .serif))
                .foregroundColor(AstroTheme.element(sign.element))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }
    }

    // MARK: - Ayraç Halkası (P1 / P2 sınırı)

    private func drawSeparatorRing(context: inout GraphicsContext, center: CGPoint) {
        var circle = Path()
        circle.addEllipse(in: CGRect(x: center.x - separatorRing,
                                     y: center.y - separatorRing,
                                     width: separatorRing * 2,
                                     height: separatorRing * 2))
        context.stroke(circle, with: .color(AstroTheme.accentSecondary.opacity(0.35)), lineWidth: 0.8)
    }

    // MARK: - Ev Çizgileri (chart1 referans)

    private func drawHouseLines(context: inout GraphicsContext, center: CGPoint) {
        for house in chart1.houses {
            let angle      = chartAngle(house.cusp)
            let outerPoint = pointOnCircle(center: center, radius: separatorRing,   angle: angle)
            let innerPoint = pointOnCircle(center: center, radius: houseRingInner, angle: angle)

            var path = Path()
            path.move(to: outerPoint)
            path.addLine(to: innerPoint)

            let isAngular = house.id == 1 || house.id == 4 || house.id == 7 || house.id == 10
            context.stroke(path,
                           with: .color(.white.opacity(isAngular ? 0.55 : 0.14)),
                           lineWidth: isAngular ? 1.0 : 0.5)
        }

        // ASC etiketi
        let ascAngle = chartAngle(chart1.houses[0].cusp)
        let ascPoint = pointOnCircle(center: center, radius: separatorRing + 3, angle: ascAngle)
        let ascText  = Text("AC").font(.system(size: size * 0.026, weight: .bold)).foregroundColor(AstroTheme.harmonik)
        context.draw(context.resolve(ascText), at: ascPoint, anchor: .trailing)
    }

    // MARK: - İç Çember

    private func drawInnerCircle(context: inout GraphicsContext, center: CGPoint) {
        var circle = Path()
        circle.addEllipse(in: CGRect(x: center.x - houseRingInner,
                                     y: center.y - houseRingInner,
                                     width: houseRingInner * 2,
                                     height: houseRingInner * 2))
        context.stroke(circle, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
    }

    // MARK: - Cross-Aspect Çizgileri

    private func drawCrossAspects(context: inout GraphicsContext, center: CGPoint) {
        let visible = crossAspects
            .filter { $0.type.isMajor }
            .sorted { $0.orb < $1.orb }
            .prefix(14)

        for aspect in visible {
            guard
                let lon1 = chart1.planets.first(where: { $0.planet == aspect.planet1 })?.longitude,
                let lon2 = chart2.planets.first(where: { $0.planet == aspect.planet2 })?.longitude
            else { continue }

            let angle1 = chartAngle(lon1)
            let angle2 = chartAngle(lon2)
            let pt1 = pointOnCircle(center: center, radius: aspectRadius, angle: angle1)
            let pt2 = pointOnCircle(center: center, radius: aspectRadius, angle: angle2)

            var path = Path()
            path.move(to: pt1)
            path.addLine(to: pt2)

            let color = AstroTheme.nature(aspect.type.nature)
            let dash: [CGFloat] = aspect.type == .sextile ? [4, 3] : []
            context.stroke(path,
                           with: .color(color.opacity(0.5)),
                           style: StrokeStyle(lineWidth: 0.9, dash: dash))
        }
    }

    // MARK: - 2. Kişi Gezegenleri (dış halka)

    private func drawPlanets2(context: inout GraphicsContext, center: CGPoint) {
        var placements = planetPlacements(from: chart2)
        resolvePlanetCollisions(&placements)

        for p in placements {
            let angle = chartAngle(p.displayDeg)
            let point = pointOnCircle(center: center, radius: p2PlanetRing, angle: angle)
            let badge = size * 0.022
            context.fill(Path(ellipseIn: CGRect(x: point.x - badge, y: point.y - badge, width: badge * 2, height: badge * 2)),
                         with: .color(AstroTheme.background.opacity(0.8)))
            let text  = Text(p.planet.glyph)
                .font(.system(size: size * 0.032, design: .serif))
                .foregroundColor(AstroTheme.planet(p.planet).opacity(0.85))
            context.draw(context.resolve(text), at: point, anchor: .center)

            drawTick(context: &context, center: center,
                     degree: p.degree,
                     outerR: signRingInner - 2, innerR: signRingInner - 8,
                     color: AstroTheme.planet(p.planet).opacity(0.45))
        }
    }

    // MARK: - 1. Kişi Gezegenleri (iç halka)

    private func drawPlanets1(context: inout GraphicsContext, center: CGPoint) {
        var placements = planetPlacements(from: chart1)
        resolvePlanetCollisions(&placements)

        for p in placements {
            let angle = chartAngle(p.displayDeg)
            let point = pointOnCircle(center: center, radius: p1PlanetRing, angle: angle)
            let badge = size * 0.024
            context.fill(Path(ellipseIn: CGRect(x: point.x - badge, y: point.y - badge, width: badge * 2, height: badge * 2)),
                         with: .color(AstroTheme.background.opacity(0.85)))
            let text  = Text(p.planet.glyph)
                .font(.system(size: size * 0.034, design: .serif))
                .foregroundColor(AstroTheme.planet(p.planet))
            context.draw(context.resolve(text), at: point, anchor: .center)

            drawTick(context: &context, center: center,
                     degree: p.degree,
                     outerR: separatorRing - 2, innerR: separatorRing - 8,
                     color: AstroTheme.planet(p.planet).opacity(0.55))
        }
    }

    // MARK: - Yardımcılar

    private func planetPlacements(from chart: BirthChart)
        -> [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)]
    {
        chart.planets
            .filter { Planet.classicPlanets.contains($0.planet) || $0.planet == .northNode || $0.planet == .chiron }
            .map { ($0.planet, $0.longitude, $0.longitude) }
    }

    private func drawTick(context: inout GraphicsContext, center: CGPoint,
                          degree: Double, outerR: CGFloat, innerR: CGFloat, color: Color) {
        let angle     = chartAngle(degree)
        let outerPt   = pointOnCircle(center: center, radius: outerR, angle: angle)
        let innerPt   = pointOnCircle(center: center, radius: innerR, angle: angle)
        var tickPath  = Path()
        tickPath.move(to: outerPt)
        tickPath.addLine(to: innerPt)
        context.stroke(tickPath, with: .color(color), lineWidth: 0.8)
    }

    private func resolvePlanetCollisions(
        _ placements: inout [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)]
    ) {
        let minGap = 9.0
        placements.sort { $0.degree < $1.degree }
        for _ in 0..<5 {
            var changed = false
            for i in 0..<placements.count {
                let j = (i + 1) % placements.count
                var diff = placements[j].displayDeg - placements[i].displayDeg
                if diff < 0 { diff += 360 }
                if diff < minGap && diff > 0 {
                    placements[i].displayDeg -= (minGap - diff) / 2
                    placements[j].displayDeg += (minGap - diff) / 2
                    if placements[i].displayDeg < 0   { placements[i].displayDeg += 360 }
                    if placements[j].displayDeg >= 360 { placements[j].displayDeg -= 360 }
                    changed = true
                }
            }
            if !changed { break }
        }
    }

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
}
