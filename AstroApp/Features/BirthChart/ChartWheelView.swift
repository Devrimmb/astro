import SwiftUI

/// Natal çark. Ascendant solda (180°), burç halkası dışta, ev halkası içte,
/// açı ağı merkezde. Renkler tamamen `AstroTheme`'den: burç dilimi element,
/// gezegen kendi rengi, açı çizgisi doğası (harmonik / zorlayıcı / nötr).
struct ChartWheelView: View {
    let chart: BirthChart
    let size: CGFloat
    /// Çark üstünde bir gezegene dokunulunca çağrılır (nil → dokunma kapalı)
    var onSelectPlanet: ((PlanetPosition) -> Void)? = nil

    private var outerRadius: CGFloat { size / 2 - 10 }
    private var signRingInner: CGFloat { outerRadius - 36 }
    private var houseRingInner: CGFloat { signRingInner - 70 }
    private var planetRingRadius: CGFloat { (signRingInner + houseRingInner) / 2 }
    private var aspectRadius: CGFloat { houseRingInner - 2 }

    /// Ascendant derecesi — chart'ın sol tarafına (9 o'clock) hizalanır
    private var ascDegree: Double {
        chart.houses.first(where: { $0.id == 1 })?.cusp ?? 0
    }

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

            drawCenterGlow(context: &context, center: center)
            drawZodiacRing(context: &context, center: center)
            drawZodiacGlyphs(context: &context, center: center)
            drawHouseLines(context: &context, center: center)
            drawHouseNumbers(context: &context, center: center)
            drawAspectLines(context: &context, center: center)
            drawPlanets(context: &context, center: center)
        }
        .frame(width: size, height: size)
        .drawingGroup()
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            guard let onSelectPlanet, let hit = planet(at: location) else { return }
            onSelectPlanet(hit)
        }
    }

    // MARK: - Dokunma

    /// Dokunulan noktaya en yakın gezegen rozetini bulur (rozet yarıçapının ~2 katı tolerans)
    private func planet(at location: CGPoint) -> PlanetPosition? {
        let center = CGPoint(x: size / 2, y: size / 2)
        let hitRadius = size * 0.06
        var best: (planet: AstroApp.Planet, distance: CGFloat)?

        for placement in planetPlacements() {
            let point = pointOnCircle(center: center, radius: planetRingRadius, angle: chartAngle(placement.displayDeg))
            let distance = hypot(point.x - location.x, point.y - location.y)
            if distance <= hitRadius, distance < (best?.distance ?? .infinity) {
                best = (placement.planet, distance)
            }
        }
        guard let best else { return nil }
        return chart.planets.first { $0.planet == best.planet }
    }

    // MARK: - Merkez ışıması

    /// Açı ağının arkasına hafif lavanta ışık — çark zemine "oturur"
    private func drawCenterGlow(context: inout GraphicsContext, center: CGPoint) {
        let r = aspectRadius + 6
        let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [AstroTheme.accent.opacity(0.16), .clear]),
                center: center, startRadius: 0, endRadius: r
            )
        )
    }

    // MARK: - Burç Halkası

    private func drawZodiacRing(context: inout GraphicsContext, center: CGPoint) {
        for sign in ZodiacSign.allCases {
            let startDeg = Double(sign.rawValue) * 30.0
            let endDeg = startDeg + 30.0

            let startAngle = chartAngle(startDeg)
            let endAngle = chartAngle(endDeg)

            let path = WheelGeometry.ringSegment(center: center, innerRadius: signRingInner, outerRadius: outerRadius,
                                                 startAngle: startAngle, endAngle: endAngle)

            context.fill(path, with: .color(AstroTheme.element(sign.element).opacity(0.26)))
            context.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.5)
        }

        // Halka sınırları — dış ve burç/ev sınırı belirgin, iç çemberler soluk
        strokeCircle(context: &context, center: center, radius: outerRadius, color: .white.opacity(0.22), lineWidth: 0.8)
        strokeCircle(context: &context, center: center, radius: signRingInner, color: .white.opacity(0.18), lineWidth: 0.8)
        strokeCircle(context: &context, center: center, radius: houseRingInner, color: .white.opacity(0.12), lineWidth: 0.6)
        strokeCircle(context: &context, center: center, radius: aspectRadius, color: .white.opacity(0.08), lineWidth: 0.5)
    }

    // MARK: - Burç Sembolleri

    private func drawZodiacGlyphs(context: inout GraphicsContext, center: CGPoint) {
        let glyphRadius = (outerRadius + signRingInner) / 2

        for sign in ZodiacSign.allCases {
            let midDeg = Double(sign.rawValue) * 30.0 + 15.0
            let point = pointOnCircle(center: center, radius: glyphRadius, angle: chartAngle(midDeg))

            let text = Text(sign.glyph)
                .font(.system(size: size * 0.045, design: .serif))
                .foregroundColor(AstroTheme.element(sign.element))
            context.draw(context.resolve(text), at: point, anchor: .center)
        }
    }

    // MARK: - Ev Çizgileri

    private func drawHouseLines(context: inout GraphicsContext, center: CGPoint) {
        for house in chart.houses {
            let isAngular = house.id == 1 || house.id == 4 || house.id == 7 || house.id == 10
            let angle = chartAngle(house.cusp)
            let outerPoint = pointOnCircle(center: center, radius: signRingInner, angle: angle)
            // Köşe evleri (ASC/IC/DSC/MC) merkeze kadar iner, diğerleri ev halkasında biter
            let innerPoint = pointOnCircle(center: center, radius: isAngular ? aspectRadius : houseRingInner, angle: angle)

            var path = Path()
            path.move(to: outerPoint)
            path.addLine(to: innerPoint)
            context.stroke(path,
                           with: .color(.white.opacity(isAngular ? 0.55 : 0.14)),
                           lineWidth: isAngular ? 1.0 : 0.5)
        }

        // ASC ve MC etiketleri — yükselen harmonik yeşil (Büyük Üçlü ile aynı), MC nötr
        let ascAngle = chartAngle(chart.houses[0].cusp)
        let ascLabelPoint = pointOnCircle(center: center, radius: outerRadius + 7, angle: ascAngle)
        let ascText = Text("AC")
            .font(.system(size: size * 0.028, weight: .bold))
            .foregroundColor(AstroTheme.harmonik)
        context.draw(context.resolve(ascText), at: ascLabelPoint, anchor: .trailing)

        if chart.houses.count >= 10 {
            let mcAngle = chartAngle(chart.houses[9].cusp)
            let mcLabelPoint = pointOnCircle(center: center, radius: outerRadius + 7, angle: mcAngle)
            let mcText = Text("MC")
                .font(.system(size: size * 0.028, weight: .bold))
                .foregroundColor(AstroTheme.textSecondary)
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

            let point = pointOnCircle(center: center, radius: houseRingInner + 12, angle: chartAngle(midDeg))

            let text = Text("\(chart.houses[i].id)")
                .font(.system(size: size * 0.025))
                .foregroundColor(AstroTheme.textTertiary)
            context.draw(context.resolve(text), at: point, anchor: .center)
        }
    }

    // MARK: - Gezegen Sembolleri

    /// Çakışması çözülmüş gezegen yerleşimleri — çizim ve dokunma aynı listeyi kullanır
    private func planetPlacements() -> [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)] {
        var placements = chart.planets.map { (planet: $0.planet, degree: $0.longitude, displayDeg: $0.longitude) }
        resolvePlanetCollisions(&placements)
        return placements
    }

    private func drawPlanets(context: inout GraphicsContext, center: CGPoint) {
        let badgeRadius = size * 0.027

        for placement in planetPlacements() {
            let color = AstroTheme.planet(placement.planet)
            let point = pointOnCircle(center: center, radius: planetRingRadius, angle: chartAngle(placement.displayDeg))

            // Glifin arkasına koyu rozet — açı ve ev çizgileri sembolü bozmasın
            let badge = CGRect(x: point.x - badgeRadius, y: point.y - badgeRadius,
                               width: badgeRadius * 2, height: badgeRadius * 2)
            context.fill(Path(ellipseIn: badge), with: .color(AstroTheme.background.opacity(0.85)))
            context.stroke(Path(ellipseIn: badge), with: .color(color.opacity(0.35)), lineWidth: 0.6)

            let text = Text(placement.planet.glyph)
                .font(.system(size: size * 0.034, design: .serif))
                .foregroundColor(color)
            context.draw(context.resolve(text), at: point, anchor: .center)

            // Gerçek pozisyona ince tick (burç halkasının iç kenarında)
            let realAngle = chartAngle(placement.degree)
            let tickOuter = pointOnCircle(center: center, radius: signRingInner - 1, angle: realAngle)
            let tickInner = pointOnCircle(center: center, radius: signRingInner - 7, angle: realAngle)
            var tickPath = Path()
            tickPath.move(to: tickOuter)
            tickPath.addLine(to: tickInner)
            context.stroke(tickPath, with: .color(color.opacity(0.8)), lineWidth: 0.9)

            // Çakışma kaydırması varsa tick ile rozeti ince çizgiyle bağla
            if abs(placement.displayDeg - placement.degree) > 0.5 {
                let badgeEdge = pointOnCircle(center: center, radius: planetRingRadius + badgeRadius, angle: chartAngle(placement.displayDeg))
                var link = Path()
                link.move(to: tickInner)
                link.addLine(to: badgeEdge)
                context.stroke(link, with: .color(color.opacity(0.3)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - Açı Çizgileri

    private func drawAspectLines(context: inout GraphicsContext, center: CGPoint) {
        for aspect in chart.aspects {
            guard let lon1 = longitude(for: aspect.point1),
                  let lon2 = longitude(for: aspect.point2) else { continue }

            let point1 = pointOnCircle(center: center, radius: aspectRadius, angle: chartAngle(lon1))
            let point2 = pointOnCircle(center: center, radius: aspectRadius, angle: chartAngle(lon2))

            var path = Path()
            path.move(to: point1)
            path.addLine(to: point2)

            let color = AstroTheme.nature(aspect.type.nature)

            // Orb daraldıkça çizgi netleşir: tam açı ≈ 0.6, orb sınırında ≈ 0.18.
            // Klasik gezegen dışı noktalar (asteroid, Lilith, düğüm…) ağı boğmasın diye çok soluk.
            let tightness = max(0, 1 - aspect.orb / max(aspect.type.orb, 0.1))
            let baseOpacity = aspect.type.isMajor ? 0.18 : 0.10
            let isCore = isCorePoint(aspect.point1) && isCorePoint(aspect.point2)
            let opacity = (baseOpacity + tightness * (aspect.type.isMajor ? 0.42 : 0.2)) * (isCore ? 1 : 0.35)

            let lineWidth: CGFloat = aspect.type.isMajor ? (aspect.type == .conjunction ? 1.1 : 0.7) : 0.45
            let dash: [CGFloat] = switch aspect.type {
            case .sextile: [4, 3]
            case .semiSextile, .quincunx: [2, 2]
            case .semiSquare, .sesquiquadrate: [1, 2]
            default: []
            }

            context.stroke(path, with: .color(color.opacity(opacity)),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash))
        }
    }

    /// Klasik 10 gezegen + AC/MC — açı ağında tam parlaklıkla çizilenler
    private func isCorePoint(_ point: ChartPoint) -> Bool {
        switch point {
        case .planet(let p): AstroApp.Planet.classicPlanets.contains(p)
        case .ascendant, .midheaven: true
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

    /// Ekliptik derece → Canvas açısı. Yükselen solda (180°), burçlar saat yönünün tersine artar (standart çark).
    private func chartAngle(_ eclipticDegree: Double) -> Angle {
        Angle(degrees: (eclipticDegree - ascDegree) + 180)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let rad = angle.radians
        return CGPoint(
            x: center.x + radius * CGFloat(Foundation.cos(rad)),
            y: center.y - radius * CGFloat(Foundation.sin(rad))
        )
    }

    private func strokeCircle(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, lineWidth: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: lineWidth)
    }

    /// Yakın gezegenlerin çakışmasını çözer (minimum 8° arayla yerleştirir)
    private func resolvePlanetCollisions(_ placements: inout [(planet: AstroApp.Planet, degree: Double, displayDeg: Double)]) {
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
                    if placements[i].displayDeg < 0 { placements[i].displayDeg += 360 }
                    if placements[j].displayDeg >= 360 { placements[j].displayDeg -= 360 }
                    changed = true
                }
            }
            if !changed { break }
        }
    }
}
