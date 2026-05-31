import SwiftUI

/// Bi-wheel chart: ic halka natal, dis halka transit gezegenleri
struct TransitBiWheelView: View {
    let natalChart: BirthChart
    let transitPositions: [PlanetPosition]
    let size: CGFloat

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
    }

    // MARK: - Zodiac Ring

    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        for sign in ZodiacSign.allCases {
            let startDeg = Double(sign.rawValue) * 30.0
            let endDeg = startDeg + 30.0
            let startAngle = chartAngle(startDeg)
            let endAngle = chartAngle(endDeg)

            var path = Path()
            path.addArc(center: center, radius: outerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.addArc(center: center, radius: signRingInner, startAngle: endAngle, endAngle: startAngle, clockwise: true)
            path.closeSubpath()

            let color: Color = switch sign.element {
            case .fire:  .red.opacity(0.13)
            case .earth: .green.opacity(0.10)
            case .air:   .yellow.opacity(0.10)
            case .water: .blue.opacity(0.13)
            }
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)

            // Burc glyph
            let midDeg = startDeg + 15.0
            let glyphRadius = (outerRadius + signRingInner) / 2
            let angle = chartAngle(midDeg)
            let point = pointOnCircle(center: center, radius: glyphRadius, angle: angle)
            let text = Text(sign.glyph).font(.system(size: size * 0.035)).foregroundColor(.white.opacity(0.8))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }

        // Circles
        for (r, w, o): (CGFloat, CGFloat, Double) in [
            (outerRadius, 1, 0.6), (signRingInner, 1, 0.6), (houseRingInner, 0.5, 0.3)
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
            context.stroke(path, with: .color(.white.opacity(isAngular ? 0.7 : 0.3)), lineWidth: isAngular ? 1.5 : 0.5)
        }
    }

    // MARK: - Natal Planets (inner)

    private func drawNatalPlanets(context: inout GraphicsContext, center: CGPoint) {
        let natalPlanets = natalChart.planets.filter { Planet.classicPlanets.contains($0.planet) }
        for pos in natalPlanets {
            let angle = chartAngle(pos.longitude)
            let point = pointOnCircle(center: center, radius: natalPlanetRadius, angle: angle)
            let glyph = planetGlyph(pos.planet)
            let text = Text(glyph).font(.system(size: size * 0.032)).foregroundColor(planetColor(pos.planet))
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
            context.fill(bgPath, with: .color(Color.black.opacity(0.6)))

            let glyph = planetGlyph(pos.planet)
            let text = Text(glyph).font(.system(size: size * 0.03)).foregroundColor(planetColor(pos.planet).opacity(0.9))
            context.draw(context.resolve(text), at: point, anchor: .center)

            // Ince cizgi - transit pozisyondan ic halkaya
            let tickOuter = pointOnCircle(center: center, radius: outerRadius, angle: angle)
            let tickInner = pointOnCircle(center: center, radius: outerRadius - 4, angle: angle)
            var tickPath = Path()
            tickPath.move(to: tickOuter)
            tickPath.addLine(to: tickInner)
            context.stroke(tickPath, with: .color(planetColor(pos.planet).opacity(0.5)), lineWidth: 1)
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

                        let color: Color = switch aspectType.nature {
                        case .harmonik: .green
                        case .zorlayici: .red
                        case .notr: .blue
                        }
                        context.stroke(path, with: .color(color.opacity(0.35)),
                                       style: StrokeStyle(lineWidth: 0.6, dash: [3, 3]))
                        break
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func chartAngle(_ eclipticDegree: Double) -> Angle {
        Angle(degrees: -(eclipticDegree - ascDegree) + 180)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(Foundation.cos(angle.radians)),
            y: center.y - radius * CGFloat(Foundation.sin(angle.radians))
        )
    }

    private func planetGlyph(_ planet: Planet) -> String {
        switch planet {
        case .sun: "☉"; case .moon: "☽"; case .mercury: "☿"; case .venus: "♀"
        case .mars: "♂"; case .jupiter: "♃"; case .saturn: "♄"; case .uranus: "♅"
        case .neptune: "♆"; case .pluto: "♇"; case .northNode: "☊"; case .chiron: "⚷"
        case .lilith: "⚸"; case .partOfFortune: "⊕"
        case .ceres: "⚳"; case .pallas: "⚴"; case .juno: "⚵"; case .vesta: "⚶"
        }
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun: .orange; case .moon: .white; case .mercury: .cyan; case .venus: .pink
        case .mars: .red; case .jupiter: .purple; case .saturn: .brown; case .uranus: .teal
        case .neptune: .indigo; case .pluto: .gray; case .northNode: .mint; case .chiron: .yellow
        case .lilith: Color(red: 0.3, green: 0, blue: 0.3); case .partOfFortune: .green
        case .ceres: Color(red: 0.6, green: 0.4, blue: 0.2)
        case .pallas: Color(red: 0.5, green: 0.7, blue: 0.9)
        case .juno: Color(red: 0.8, green: 0.4, blue: 0.6)
        case .vesta: Color(red: 0.9, green: 0.5, blue: 0.2)
        }
    }
}
