import SwiftUI

/// Bi-wheel chart: ic halka natal, dis halka transit gezegenleri
struct TransitBiWheelView: View {
    let natalChart: BirthChart
    let transitPositions: [PlanetPosition]
    let size: CGFloat
    /// Vurgulanan natal gezegen: ona gelen transit açıları parlar, diğerleri söner
    var highlightedPlanet: Planet? = nil
    /// Natal gezegen rozetine dokunulunca (nil → dokunma kapalı)
    var onSelectPlanet: ((Planet) -> Void)? = nil

    private var outerRadius: CGFloat { size / 2 - 10 }
    private var transitRingRadius: CGFloat { outerRadius - 18 }
    private var signRingInner: CGFloat { outerRadius - 36 }
    private var houseRingInner: CGFloat { signRingInner - 60 }
    private var natalPlanetRadius: CGFloat { (signRingInner + houseRingInner) / 2 }
    private var innerRadius: CGFloat { houseRingInner }

    private var ascDegree: Double {
        natalChart.houses.first(where: { $0.id == 1 })?.cusp ?? 0
    }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            drawZodiacRing(context: &context, center: center)
            drawHouseLines(context: &context, center: center)
            drawNatalPlanets(context: &context, center: center)
            drawTransitPlanets(context: &context, center: center)
            drawAspectLines(context: &context, center: center)
        }
        .frame(width: size, height: size)
        .drawingGroup()
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            guard let onSelectPlanet, let hit = natalPlanet(at: location) else { return }
            onSelectPlanet(hit)
        }
    }

    // MARK: - Dokunma

    private func natalPlanet(at location: CGPoint) -> Planet? {
        let center = CGPoint(x: size / 2, y: size / 2)
        let hitRadius = size * 0.055
        var best: (planet: Planet, distance: CGFloat)?
        for pos in natalChart.planets where Planet.classicPlanets.contains(pos.planet) {
            let point = pointOnCircle(center: center, radius: natalPlanetRadius, angle: chartAngle(pos.longitude))
            let distance = hypot(point.x - location.x, point.y - location.y)
            if distance <= hitRadius, distance < (best?.distance ?? .infinity) {
                best = (pos.planet, distance)
            }
        }
        return best?.planet
    }

    // MARK: - Zodiac Ring

    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        for sign in ZodiacSign.allCases {
            let startDeg = Double(sign.rawValue) * 30.0
            let endDeg = startDeg + 30.0
            let startAngle = chartAngle(startDeg)
            let endAngle = chartAngle(endDeg)

            let path = WheelGeometry.ringSegment(center: center, innerRadius: signRingInner, outerRadius: outerRadius,
                                                 startAngle: startAngle, endAngle: endAngle)

            let color = AstroTheme.element(sign.element).opacity(0.22)
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.5)

            // Burc glyph
            let midDeg = startDeg + 15.0
            let glyphRadius = (outerRadius + signRingInner) / 2
            let angle = chartAngle(midDeg)
            let point = pointOnCircle(center: center, radius: glyphRadius, angle: angle)
            let text = Text(sign.glyph)
                .font(.system(size: size * 0.036, design: .serif))
                .foregroundColor(AstroTheme.element(sign.element))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }

        // Dış transit halkası — kesikli, ikincil renk
        var transitRing = Path()
        transitRing.addEllipse(in: CGRect(x: center.x - outerRadius - 2, y: center.y - outerRadius - 2,
                                          width: (outerRadius + 2) * 2, height: (outerRadius + 2) * 2))
        context.stroke(transitRing, with: .color(AstroTheme.accentSecondary.opacity(0.25)),
                       style: StrokeStyle(lineWidth: 0.6, dash: [1.5, 2.5]))

        // Circles
        for (r, w, o): (CGFloat, CGFloat, Double) in [
            (outerRadius, 0.8, 0.22), (signRingInner, 0.8, 0.18), (houseRingInner, 0.5, 0.12)
        ] {
            var circle = Path()
            circle.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
            context.stroke(circle, with: .color(.white.opacity(o)), lineWidth: w)
        }
    }

    // MARK: - House Lines

    private func drawHouseLines(context: inout GraphicsContext, center: CGPoint) {
        for house in natalChart.houses {
            let angle = chartAngle(house.cusp)
            let outer = pointOnCircle(center: center, radius: signRingInner, angle: angle)
            let inner = pointOnCircle(center: center, radius: houseRingInner, angle: angle)
            var path = Path()
            path.move(to: outer)
            path.addLine(to: inner)
            let isAngular = [1, 4, 7, 10].contains(house.id)
            context.stroke(path, with: .color(.white.opacity(isAngular ? 0.55 : 0.14)), lineWidth: isAngular ? 1.0 : 0.5)
        }

        // AC etiketi — natal çarkla aynı konvansiyon
        if let asc = natalChart.houses.first(where: { $0.id == 1 }) {
            let point = pointOnCircle(center: center, radius: signRingInner - 4, angle: chartAngle(asc.cusp))
            let text = Text("AC").font(.system(size: size * 0.024, weight: .bold)).foregroundColor(AstroTheme.harmonik)
            context.draw(context.resolve(text), at: point, anchor: .leading)
        }
    }

    // MARK: - Natal Planets (inner)

    private func drawNatalPlanets(context: inout GraphicsContext, center: CGPoint) {
        let natalPlanets = natalChart.planets.filter { Planet.classicPlanets.contains($0.planet) }
        for pos in natalPlanets {
            let angle = chartAngle(pos.longitude)
            let point = pointOnCircle(center: center, radius: natalPlanetRadius, angle: angle)
            let color = AstroTheme.planet(pos.planet)
            let badge = size * 0.024
            let isHighlighted = highlightedPlanet == pos.planet
            let dimmed = highlightedPlanet != nil && !isHighlighted
            if isHighlighted {
                let glow = badge * 2.6
                context.fill(Path(ellipseIn: CGRect(x: point.x - glow, y: point.y - glow, width: glow * 2, height: glow * 2)),
                             with: .radialGradient(Gradient(colors: [color.opacity(0.5), .clear]),
                                                   center: point, startRadius: 0, endRadius: glow))
            }
            let badgePath = Path(ellipseIn: CGRect(x: point.x - badge, y: point.y - badge, width: badge * 2, height: badge * 2))
            context.fill(badgePath, with: .color(AstroTheme.background.opacity(0.85)))
            if isHighlighted {
                context.stroke(badgePath, with: .color(color), lineWidth: 1.4)
            }
            let text = Text(pos.planet.glyph).font(.system(size: size * 0.032, design: .serif))
                .foregroundColor(color.opacity(dimmed ? 0.4 : 1))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }
    }

    // MARK: - Transit Planets (outer ring)

    private func drawTransitPlanets(context: inout GraphicsContext, center: CGPoint) {
        for pos in transitPositions {
            let angle = chartAngle(pos.longitude)
            let point = pointOnCircle(center: center, radius: transitRingRadius, angle: angle)

            // Arka plan daire
            var bgPath = Path()
            bgPath.addEllipse(in: CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16))
            context.fill(bgPath, with: .color(AstroTheme.background.opacity(0.85)))

            let text = Text(pos.planet.glyph)
                .font(.system(size: size * 0.03, design: .serif))
                .foregroundColor(AstroTheme.planet(pos.planet).opacity(0.95))
            context.draw(context.resolve(text), at: point, anchor: .center)
            if pos.isRetrograde {
                let rx = Text("℞").font(.system(size: size * 0.016, weight: .bold)).foregroundColor(AstroTheme.zorlayici)
                context.draw(context.resolve(rx), at: CGPoint(x: point.x + 7, y: point.y - 7), anchor: .center)
            }

            // Ince cizgi - transit pozisyondan ic halkaya
            let tickOuter = pointOnCircle(center: center, radius: outerRadius, angle: angle)
            let tickInner = pointOnCircle(center: center, radius: outerRadius - 4, angle: angle)
            var tickPath = Path()
            tickPath.move(to: tickOuter)
            tickPath.addLine(to: tickInner)
            context.stroke(tickPath, with: .color(AstroTheme.planet(pos.planet).opacity(0.5)), lineWidth: 1)
        }
    }

    // MARK: - Transit-Natal Aspect Lines

    private func drawAspectLines(context: inout GraphicsContext, center: CGPoint) {
        let aspectRadius = houseRingInner - 2
        let natalPlanets = natalChart.planets.filter { Planet.classicPlanets.contains($0.planet) }

        for transit in transitPositions {
            for natal in natalPlanets {
                var diff = abs(transit.longitude - natal.longitude)
                if diff > 180 { diff = 360 - diff }

                for aspectType in AspectType.allCases {
                    let orb = abs(diff - aspectType.rawValue)
                    if orb <= aspectType.orb * 0.5 { // Sadece dar orb'lu acilari ciz
                        let angle1 = chartAngle(transit.longitude)
                        let angle2 = chartAngle(natal.longitude)
                        let p1 = pointOnCircle(center: center, radius: aspectRadius, angle: angle1)
                        let p2 = pointOnCircle(center: center, radius: aspectRadius, angle: angle2)

                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)

                        let color = AstroTheme.nature(aspectType.nature)
                        let involved = highlightedPlanet == nil || natal.planet == highlightedPlanet
                        let opacity: Double = highlightedPlanet == nil ? 0.35 : (involved ? 0.9 : 0.06)
                        context.stroke(path, with: .color(color.opacity(opacity)),
                                       style: StrokeStyle(lineWidth: involved && highlightedPlanet != nil ? 1.4 : 0.6,
                                                          dash: involved && highlightedPlanet != nil ? [] : [3, 3]))
                        break
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func chartAngle(_ eclipticDegree: Double) -> Angle {
        Angle(degrees: (eclipticDegree - ascDegree) + 180)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(Foundation.cos(angle.radians)),
            y: center.y - radius * CGFloat(Foundation.sin(angle.radians))
        )
    }
}
