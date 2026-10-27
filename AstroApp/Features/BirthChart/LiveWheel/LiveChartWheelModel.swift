import SwiftUI

// MARK: - Yaşayan çark motoru
//
// Doğum haritası sayfasındaki çarkın fiziği ve çizimi. Gezegenler, yükselen ve ev
// uçları birer yay (spring) ile hedefe gider; kişi değişince çark "yaylanarak" yeni
// haritaya oturur. Dört mod:
//   home   — çark yavaş döner (drift), sadece Güneş ve Ay görünür
//   calc   — çark bir tam tur atar, gezegenler sırayla içeri uçar, açılar tek tek çizilir
//   result — çark sabit, tüm gezegen/ev/açılar; gezegene dokununca açıları parlar
//   manual — tüm gezegenler görünür, manuel giriş sheet'i tekerlek çevirdikçe canlı akar
//
// Çizim `ChartWheelView` ile aynı konvansiyonu kullanır: yükselen solda (180°),
// burçlar saat yönünün tersine artar, renkler `AstroTheme`'den.

@MainActor
@Observable
final class LiveChartWheelModel {
    enum Mode { case home, calc, result, manual }

    private(set) var mode: Mode = .home

    /// Sonuç modunda vurgulanan gezegen (çarka dokunma ya da listeden seçim)
    var selectedPlanet: Planet? {
        didSet { if selectedPlanet != oldValue { selectionHaptic.selectionChanged() } }
    }

    /// Dışarıdan tetiklenen her değişimde artar; görünüm bununla uyanır (durdurulmuş TimelineView)
    private(set) var revision = 0

    @ObservationIgnored var reduceMotion = false

    /// Çarkta gösterilen gök cisimleri (klasik 10 gezegen) — sabit sıra
    static let bodies: [Planet] = Planet.classicPlanets

    private struct Spring {
        var v = 0.0
        var vel = 0.0
        var target: Double?

        /// Hedefe yaylanır; hâlâ hareket ediyorsa true döner
        mutating func step(_ dt: Double) -> Bool {
            guard let target else { return false }
            let diff = LiveChartWheelModel.wrap(target - v)
            let acc = 110 * diff - 17 * vel
            vel += acc * dt
            v += vel * dt
            if abs(diff) < 0.02 && abs(vel) < 0.05 {
                v = target
                vel = 0
                return false
            }
            return true
        }

        mutating func settle() {
            if let target { v = target }
            vel = 0
        }
    }

    private struct AspectLine {
        let a: Int
        let b: Int
        let type: AspectType
    }

    // Yaylar: yükselen, 10 gezegen, 12 ev ucu (yükselene göre ofset)
    @ObservationIgnored private var ascSpring = Spring()
    @ObservationIgnored private var planetSprings = Array(repeating: Spring(), count: LiveChartWheelModel.bodies.count)
    @ObservationIgnored private var cuspSprings = (0..<12).map { Spring(v: Double($0) * 30, vel: 0, target: Double($0) * 30) }
    @ObservationIgnored private var hasTargets = false

    // Görünürlük / sahne durumu
    @ObservationIgnored private var alpha = Array(repeating: 0.0, count: LiveChartWheelModel.bodies.count)
    @ObservationIgnored private var flyRadius = Array(repeating: 1.0, count: LiveChartWheelModel.bodies.count)
    @ObservationIgnored private var landed = Array(repeating: false, count: LiveChartWheelModel.bodies.count)
    @ObservationIgnored private var houseAlpha = 0.0
    @ObservationIgnored private var aspectAlpha = 0.0
    @ObservationIgnored private var drift = 0.0
    @ObservationIgnored private var driftAnim: (from: Double, to: Double, start: Double, dur: Double)?
    @ObservationIgnored private var calcStart = 0.0
    @ObservationIgnored private var calcFly = true
    @ObservationIgnored private var aspects: [AspectLine] = []
    @ObservationIgnored private var glyphPositions: [Int: CGPoint] = [:]
    @ObservationIgnored private var lastTick: Double?

    /// Son adımda bir şey hareket ediyor muydu (TimelineView'ı durdurmak için)
    @ObservationIgnored private(set) var isMoving = true

    // Zamanlama (saniye) — prototipteki değerler
    private let planetDelay = 0.20
    private let planetStep = 0.07
    private let planetDuration = 0.55
    private let aspectStart = 1.15
    private let aspectStep = 0.035
    private let aspectDuration = 0.38
    private let resultAfterFly = 1.95
    private let resultAfterSettle = 1.65

    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let landingHaptic = UIImpactFeedbackGenerator(style: .light)
    private let resultHaptic = UINotificationFeedbackGenerator()

    // MARK: Hedefler

    /// Çarkı bir haritaya yönlendirir. `instant` → yaylanmadan doğrudan oturur.
    func setTargets(chart: BirthChart, instant: Bool = false) {
        let asc = chart.houses.first(where: { $0.id == 1 })?.cusp ?? 0
        ascSpring.target = asc

        for (i, planet) in Self.bodies.enumerated() {
            guard let lon = chart.planets.first(where: { $0.planet == planet })?.longitude else { continue }
            planetSprings[i].target = lon
        }

        if chart.houses.count == 12 {
            for (i, house) in chart.houses.sorted(by: { $0.id < $1.id }).enumerated() {
                cuspSprings[i].target = Self.norm(house.cusp - asc)
            }
        } else {
            for i in 0..<12 { cuspSprings[i].target = Double(i) * 30 }
        }

        aspects = chart.aspects.compactMap { aspect in
            guard aspect.type.isMajor,
                  case .planet(let p1) = aspect.point1,
                  case .planet(let p2) = aspect.point2,
                  let a = Self.bodies.firstIndex(of: p1),
                  let b = Self.bodies.firstIndex(of: p2) else { return nil }
            return AspectLine(a: a, b: b, type: aspect.type)
        }

        if instant || !hasTargets {
            ascSpring.settle()
            for i in planetSprings.indices { planetSprings[i].settle() }
            for i in cuspSprings.indices { cuspSprings[i].settle() }
        }
        hasTargets = true
        wake()
    }

    // MARK: Mod geçişleri

    func enterHome() {
        mode = .home
        selectedPlanet = nil
        driftAnim = nil
        wake()
    }

    /// Hesaplama sahnesini başlatır; sonuç moduna geçilmesi gereken süreyi (sn) döner.
    @discardableResult
    func startCalculation(fly: Bool) -> TimeInterval {
        let now = Date().timeIntervalSinceReferenceDate
        mode = .calc
        selectedPlanet = nil
        calcFly = fly && !reduceMotion
        calcStart = now
        for i in landed.indices { landed[i] = false }
        driftAnim = (drift, ceil(drift / 360) * 360 + (reduceMotion ? 0 : 360), now, reduceMotion ? 0.01 : 1.6)
        wake()
        return reduceMotion ? 0.3 : (calcFly ? resultAfterFly : resultAfterSettle)
    }

    func showResult(haptic: Bool = true) {
        mode = .result
        driftAnim = nil
        drift = 0
        selectedPlanet = nil
        wake()
        if haptic { resultHaptic.notificationOccurred(.success) }
    }

    func openManual() {
        let now = Date().timeIntervalSinceReferenceDate
        mode = .manual
        selectedPlanet = nil
        driftAnim = (drift, ceil(drift / 360) * 360, now, reduceMotion ? 0.01 : 0.7)
        wake()
    }

    func closeManual() {
        mode = .home
        wake()
    }

    func toggleSelection(_ planet: Planet) {
        selectedPlanet = selectedPlanet == planet ? nil : planet
        wake()
    }

    private func wake() {
        isMoving = true
        revision &+= 1
    }

    // MARK: Dokunma

    /// Dokunulan noktaya en yakın gezegen rozeti (çark boyutuna göre tolerans)
    func planet(at point: CGPoint, size: CGFloat) -> Planet? {
        let hit = size * 0.075
        var best: (index: Int, distance: CGFloat)?
        for (i, p) in glyphPositions {
            let d = hypot(p.x - point.x, p.y - point.y)
            if d < hit, d < (best?.distance ?? .infinity) { best = (i, d) }
        }
        guard let best else { return nil }
        return Self.bodies[best.index]
    }

    // MARK: Fizik

    func step(now: Double) {
        let dt = min(0.05, max(0, now - (lastTick ?? now)))
        lastTick = now
        var moving = false

        // Yaylar
        moving = ascSpring.step(dt) || moving
        for i in planetSprings.indices { moving = planetSprings[i].step(dt) || moving }
        for i in cuspSprings.indices { moving = cuspSprings[i].step(dt) || moving }

        // Drift
        if let anim = driftAnim {
            let t = Self.clamp01((now - anim.start) / anim.dur)
            drift = anim.from + (anim.to - anim.from) * Self.easeInOut(t)
            if t >= 1 { drift = 0; driftAnim = nil }
            moving = true
        } else if mode == .home && !reduceMotion {
            drift += dt * 3
            moving = true
        }

        // Görünürlük
        let showAll = mode != .home
        for i in alpha.indices {
            if mode == .calc && calcFly && i >= 2 {
                let t = Self.clamp01((now - calcStart - planetDelay - Double(i - 2) * planetStep) / planetDuration)
                alpha[i] = t
                flyRadius[i] = 1.4 - 0.4 * Self.easeBack(t)
                if t >= 0.7 && !landed[i] {
                    landed[i] = true
                    landingHaptic.impactOccurred(intensity: 0.55)
                }
                moving = true
            } else {
                let target = showAll || i < 2 ? 1.0 : 0.0
                let next = alpha[i] + (target - alpha[i]) * min(1, dt / 0.25)
                if abs(next - alpha[i]) > 0.001 { moving = true }
                alpha[i] = next
                flyRadius[i] = 1
            }
        }
        let houseTarget = showAll ? 1.0 : 0.0
        let nextHouse = houseAlpha + (houseTarget - houseAlpha) * min(1, dt / 0.4)
        if abs(nextHouse - houseAlpha) > 0.001 { moving = true }
        houseAlpha = nextHouse
        let nextAspect = aspectAlpha + (houseTarget - aspectAlpha) * min(1, dt / 0.3)
        if abs(nextAspect - aspectAlpha) > 0.001 { moving = true }
        aspectAlpha = nextAspect

        if mode == .calc { moving = true }
        isMoving = moving
    }

    // MARK: Çizim

    func draw(in ctx: GraphicsContext, size: CGSize, now: Double) {
        let S = min(size.width, size.height)
        let cx = size.width / 2, cy = size.height / 2
        let R = S / 2 - 6
        let signInner = R * 0.83
        let planetRadius = R * 0.725
        let houseOuter = R * 0.63
        let aspectRadius = R * 0.52
        let asc = ascSpring.v

        func angle(_ lon: Double) -> Double { (180 + lon - asc + drift) * .pi / 180 }
        func point(_ lon: Double, _ r: CGFloat) -> CGPoint {
            let a = angle(lon)
            return CGPoint(x: cx + r * CGFloat(cos(a)), y: cy - r * CGFloat(sin(a)))
        }
        func circle(_ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // Merkez ışıması
        ctx.fill(circle(R), with: .radialGradient(
            Gradient(stops: [.init(color: AstroTheme.accent.opacity(0.20), location: 0),
                             .init(color: AstroTheme.accent.opacity(0.05), location: 0.7),
                             .init(color: .clear, location: 1)]),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: R))

        // Burç halkası
        for sign in ZodiacSign.allCases {
            let start = Double(sign.rawValue) * 30
            let segment = WheelGeometry.ringSegment(
                center: CGPoint(x: cx, y: cy), innerRadius: signInner, outerRadius: R,
                startAngle: Angle(radians: angle(start)), endAngle: Angle(radians: angle(start + 30)))
            let color = AstroTheme.element(sign.element)
            ctx.fill(segment, with: .color(color.opacity(0.22)))
            ctx.stroke(segment, with: .color(.white.opacity(0.10)), lineWidth: 0.5)

            let glyph = Text(sign.glyph)
                .font(.system(size: R * 0.1, design: .serif))
                .foregroundColor(color)
            ctx.draw(ctx.resolve(glyph), at: point(start + 15, (R + signInner) / 2), anchor: .center)
        }
        ctx.stroke(circle(R), with: .color(.white.opacity(0.22)), lineWidth: 0.8)
        ctx.stroke(circle(signInner), with: .color(.white.opacity(0.18)), lineWidth: 0.8)

        // Derece tikleri (5° / 10°)
        var ticks = Path()
        for d in stride(from: 0, to: 360, by: 5) {
            let len = d % 10 == 0 ? R * 0.03 : R * 0.015
            ticks.move(to: point(Double(d), signInner))
            ticks.addLine(to: point(Double(d), signInner - len))
        }
        ctx.stroke(ticks, with: .color(.white.opacity(0.22)), lineWidth: 0.6)

        // Evler
        if houseAlpha > 0.01 {
            var layer = ctx
            layer.opacity = houseAlpha
            layer.stroke(circle(houseOuter), with: .color(.white.opacity(0.12)), lineWidth: 0.6)
            layer.stroke(circle(aspectRadius), with: .color(.white.opacity(0.08)), lineWidth: 0.5)
            for h in 0..<12 {
                let lon = asc + cuspSprings[h].v
                let next = asc + cuspSprings[(h + 1) % 12].v + (h == 11 ? 360 : 0)
                let isAngular = h % 3 == 0
                var line = Path()
                line.move(to: point(lon, aspectRadius))
                line.addLine(to: point(lon, signInner))
                layer.stroke(line, with: .color(isAngular ? AstroTheme.gold.opacity(0.55) : .white.opacity(0.16)),
                             lineWidth: isAngular ? 1.2 : 0.6)

                var span = Self.norm(next - lon)
                if span == 0 { span = 30 }
                let number = Text("\(h + 1)")
                    .font(.system(size: R * 0.05, weight: .medium))
                    .foregroundColor(AstroTheme.textTertiary)
                layer.draw(layer.resolve(number), at: point(lon + span / 2, (houseOuter + aspectRadius) / 2), anchor: .center)
            }
        }

        // Yükselen işareti (altın üçgen + AC)
        do {
            let a = angle(asc)
            let tip = point(asc, R + 1)
            let s = R * 0.045
            var tri = Path()
            tri.move(to: CGPoint(x: tip.x - cos(a) * s * 1.2, y: tip.y + sin(a) * s * 1.2))
            tri.addLine(to: CGPoint(x: tip.x + cos(a + .pi / 2) * s * 0.7, y: tip.y - sin(a + .pi / 2) * s * 0.7))
            tri.addLine(to: CGPoint(x: tip.x - cos(a + .pi / 2) * s * 0.7, y: tip.y + sin(a + .pi / 2) * s * 0.7))
            tri.closeSubpath()
            ctx.fill(tri, with: .color(AstroTheme.gold))
        }

        // Açılar
        let staged = (mode == .calc || mode == .result) && calcFly && !reduceMotion
        let selectedIndex = selectedPlanet.flatMap { Self.bodies.firstIndex(of: $0) }
        if aspectAlpha > 0.01 {
            for (i, aspect) in aspects.enumerated() {
                let t = staged ? Self.clamp01((now - calcStart - aspectStart - Double(i) * aspectStep) / aspectDuration) : 1
                if t <= 0 { continue }
                let p1 = point(planetSprings[aspect.a].v, aspectRadius)
                let p2 = point(planetSprings[aspect.b].v, aspectRadius)
                let e = Self.easeInOut(t)
                let end = CGPoint(x: p1.x + (p2.x - p1.x) * e, y: p1.y + (p2.y - p1.y) * e)

                let involved = selectedIndex == nil || aspect.a == selectedIndex || aspect.b == selectedIndex
                let opacity: Double = selectedIndex == nil ? 0.55 : (involved ? 0.95 : 0.08)
                let width: CGFloat = selectedIndex != nil && involved ? 1.8 : (aspect.type == .conjunction ? 1.3 : 1.0)
                let dash: [CGFloat] = aspect.type == .sextile ? [4, 3] : []

                var line = Path()
                line.move(to: p1)
                line.addLine(to: end)
                var layer = ctx
                layer.opacity = aspectAlpha * opacity
                layer.stroke(line, with: .color(AstroTheme.nature(aspect.type.nature)),
                             style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
            }
        }

        // Gezegenler
        // Hedef yoksa (hiç kişi yok) gezegen çizilmez — boş çark
        let visible = hasTargets ? alpha.indices.filter { alpha[$0] > 0.02 } : []
        let spread = spreadLongitudes(visible)
        glyphPositions.removeAll(keepingCapacity: true)
        let badgeRadius = R * 0.062

        for i in visible {
            let planet = Self.bodies[i]
            let color = AstroTheme.planet(planet)
            let trueLon = planetSprings[i].v
            var layer = ctx
            layer.opacity = alpha[i]

            // Gerçek konuma tik
            var tick = Path()
            tick.move(to: point(trueLon, signInner))
            tick.addLine(to: point(trueLon, signInner - R * 0.05))
            layer.stroke(tick, with: .color(color.opacity(0.85)), lineWidth: 1.1)

            let displayLon = spread[i] ?? trueLon
            let p = point(displayLon, planetRadius * flyRadius[i])
            let isSelected = selectedIndex == i
            let glow = isSelected || (mode == .home && i < 2)

            if glow {
                let gr = badgeRadius * 2.4
                layer.fill(Path(ellipseIn: CGRect(x: p.x - gr, y: p.y - gr, width: gr * 2, height: gr * 2)),
                           with: .radialGradient(Gradient(colors: [color.opacity(isSelected ? 0.55 : 0.3), .clear]),
                                                 center: p, startRadius: 0, endRadius: gr))
            }

            let badge = Path(ellipseIn: CGRect(x: p.x - badgeRadius, y: p.y - badgeRadius,
                                               width: badgeRadius * 2, height: badgeRadius * 2))
            layer.fill(badge, with: .color(AstroTheme.background.opacity(0.9)))
            layer.stroke(badge, with: .color(color.opacity(isSelected ? 1 : 0.55)), lineWidth: isSelected ? 1.6 : 1)

            let glyph = Text(planet.glyph)
                .font(.system(size: badgeRadius * 1.25, design: .serif))
                .foregroundColor(color)
            layer.draw(layer.resolve(glyph), at: CGPoint(x: p.x, y: p.y + badgeRadius * 0.05), anchor: .center)

            // Çakışma kaydırması varsa tik ile rozeti bağla
            if abs(Self.wrap(displayLon - trueLon)) > 0.5 {
                var link = Path()
                link.move(to: point(trueLon, signInner - R * 0.05))
                link.addLine(to: point(displayLon, planetRadius * flyRadius[i] + badgeRadius))
                layer.stroke(link, with: .color(color.opacity(0.3)), lineWidth: 0.5)
            }

            if aspectAlpha > 0.01 {
                let d = point(trueLon, aspectRadius)
                layer.fill(Path(ellipseIn: CGRect(x: d.x - 2, y: d.y - 2, width: 4, height: 4)), with: .color(color))
            }

            glyphPositions[i] = p
        }
    }

    // MARK: Yardımcılar

    /// Yakın gezegen rozetlerini en az 9° arayla ayırır (tik gerçek derecede kalır)
    private func spreadLongitudes(_ indices: [Int]) -> [Int: Double] {
        var items = indices.map { (index: $0, lon: Self.norm(planetSprings[$0].v)) }
        guard items.count > 1 else {
            return Dictionary(uniqueKeysWithValues: items.map { ($0.index, $0.lon) })
        }
        items.sort { $0.lon < $1.lon }
        let minGap = 9.0
        for _ in 0..<6 {
            for i in items.indices {
                let j = (i + 1) % items.count
                var gap = items[j].lon - items[i].lon
                if i == items.count - 1 { gap += 360 }
                if gap < minGap {
                    let push = (minGap - gap) / 2
                    items[i].lon -= push
                    items[j].lon += push
                }
            }
        }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.index, $0.lon) })
    }

    static func norm(_ x: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// −180…180 aralığına sarar
    static func wrap(_ d: Double) -> Double {
        norm(d + 180) - 180
    }

    static func clamp01(_ t: Double) -> Double { max(0, min(1, t)) }

    static func easeInOut(_ t: Double) -> Double {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    static func easeBack(_ t: Double) -> Double {
        let c = 1.5
        return 1 + (c + 1) * pow(t - 1, 3) + c * pow(t - 1, 2)
    }
}
