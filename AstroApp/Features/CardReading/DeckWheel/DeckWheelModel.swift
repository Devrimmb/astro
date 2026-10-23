import SwiftUI

// MARK: - Yardımcı tipler

/// Bir kartın ekrandaki konumu: merkez, dönüş (derece), ölçek, opaklık.
struct DeckPose {
    var x: Double, y: Double, r: Double, s: Double, o: Double

    static func lerp(_ a: DeckPose, _ b: DeckPose, _ t: Double) -> DeckPose {
        DeckPose(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t,
                 r: a.r + (b.r - a.r) * t, s: a.s + (b.s - a.s) * t,
                 o: a.o + (b.o - a.o) * t)
    }
}

/// Çarktan seçilmiş bir kart. Canvas'tan çıkarılıp SwiftUI view'ı olarak çizilir.
struct DeckPick<Card>: Identifiable {
    let id: Int            // destedeki fiziksel kart indeksi
    let card: Card
    let reversed: Bool
    let slot: Int
    let start: DeckPose    // çarktan koptuğu an
    var landed = false
    var flipped = false
}

private struct DeckSlotCard<Card> {
    enum Mode { case stack, wheel, picked }
    let index: Int
    var card: Card
    var reversed = false
    var mode: Mode = .stack
    var from: DeckPose?
    var t0 = 0.0, dur = 1.0, delay = 0.0
    var pose = DeckPose(x: 0, y: 0, r: 0, s: 1, o: 1)
    var jx: Double, jy: Double, jr: Double
    var visible = true
}

private struct DeckParticle { var x, y, vx, vy, life, max, r: Double; var gold: Bool }

// MARK: - Model / animasyon motoru
//
// Destedeki tüm kartlar tek bir Canvas içinde çizilir (tek katman, çok hızlı).
// Seçilen kartlar Canvas'tan çıkarılıp normal SwiftUI view'ı olarak üstte gösterilir
// (3D çevirme, parıltı ve net yazı için). Tarot, Katina, Rün, Tanrı kartı gibi
// her deste için aynı motor kullanılır; kart tipi generic'tir.

@MainActor
@Observable
final class DeckWheelModel<Card> {
    enum Phase { case idle, shuffle, spread, ready, reveal, reading, collapse }

    private(set) var phase: Phase = .idle
    var picked: [DeckPick<Card>] = []

    let deck: [Card]
    let pickCount: Int
    let allowsReversed: Bool
    let aspect: Double              // kart boy/en oranı

    // Geometri
    @ObservationIgnored private(set) var wheelCardSize = CGSize(width: 60, height: 96)
    @ObservationIgnored private(set) var bigCardSize = CGSize(width: 125, height: 200)
    @ObservationIgnored private(set) var W = 0.0
    @ObservationIgnored private(set) var H = 0.0
    @ObservationIgnored private var radius = 300.0
    @ObservationIgnored private var centerY0 = 0.0

    @ObservationIgnored var reduceMotion = false

    // Fizik ayarları
    let count: Int
    let step: Double                // kartlar arası açı (derece)
    private let liftFactor = 0.3    // kalkma yüksekliği (kart boyunun oranı)
    private let friction = 0.93     // momentum sürtünmesi (16 ms başına)
    @ObservationIgnored private var liftSigma: Double { max(4.2, step * 0.9) }

    @ObservationIgnored private var cards: [DeckSlotCard<Card>] = []
    @ObservationIgnored private var drawOrder: [Int] = []
    @ObservationIgnored private var hotIndex: Int?
    @ObservationIgnored private var particles: [DeckParticle] = []

    @ObservationIgnored private var wheelAngle = 0.0   // derece
    @ObservationIgnored private var velocity = 0.0     // derece/sn
    @ObservationIgnored private var drop = 0.0
    @ObservationIgnored private var dropTarget = 0.0
    @ObservationIgnored private var liftAmt = 0.0
    @ObservationIgnored private var glowAlpha = 0.0
    @ObservationIgnored private var dragging = false
    @ObservationIgnored private var lastX = 0.0
    @ObservationIgnored private var lastMoveTime = Date()
    @ObservationIgnored private var moved = 0.0
    @ObservationIgnored private var lastTick: Double?
    @ObservationIgnored private var shuffleStart = 0.0
    @ObservationIgnored private var runID = 0

    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let impactHaptic = UIImpactFeedbackGenerator(style: .medium)

    init(deck: [Card], pickCount: Int = 1, allowsReversed: Bool = false, aspect: Double = 1.6) {
        precondition(!deck.isEmpty, "Deste boş olamaz")
        self.deck = deck
        self.pickCount = max(1, min(pickCount, deck.count))
        self.allowsReversed = allowsReversed
        self.aspect = aspect
        count = deck.count
        step = 360.0 / Double(deck.count)
        cards = (0..<count).map { i in
            DeckSlotCard(index: i, card: deck[0],
                         jx: .random(in: -2...2), jy: -Double(i) * 0.22, jr: .random(in: -2.5...2.5))
        }
        assignFaces()
    }

    // MARK: Dışa açık durum

    var isPicking: Bool { !picked.isEmpty || phase == .reading }
    var showsStartButton: Bool { phase == .idle }

    var counterText: String? {
        switch phase {
        case .spread: return "\(count) kart seriliyor…"
        case .ready:
            return picked.isEmpty
                ? "\(count) kart masada. Kaydır, sana çekeni dokunarak seç."
                : "\(pickCount - picked.count) kart daha seç"
        default: return nil
        }
    }

    var slotScale: Double {
        pickCount == 1 ? 1 : (W * 0.26) / Double(bigCardSize.width)
    }

    func slotCenter(_ slot: Int) -> CGPoint {
        if pickCount == 1 { return CGPoint(x: W / 2, y: H * 0.36) }
        let mid = Double(pickCount - 1) / 2
        return CGPoint(x: W / 2 + (Double(slot) - mid) * W * 0.3, y: H * 0.35)
    }

    /// Okuma panelinin üst kenarı (ekran yüksekliğinin oranı)
    var panelTop: Double { 0.52 }

    // MARK: Yerleşim

    func layout(_ s: CGSize) {
        guard s.width > 0, s.height > 0, s.width != W || s.height != H else { return }
        let first = W == 0
        W = s.width; H = s.height
        let bw = min(W * 0.32, 150)
        bigCardSize = CGSize(width: bw, height: bw * aspect)
        let ww = max(50, min(W * 0.165, 68))
        wheelCardSize = CGSize(width: ww, height: ww * aspect)
        radius = min(W * 0.8, 340)
        centerY0 = H * 0.715 + radius
        if first {
            let t = now()
            for i in cards.indices { cards[i].pose = stackPose(cards[i], t); cards[i].from = nil }
        }
        if phase == .reading { dropTarget = H * 0.42 }
    }

    // MARK: Akış

    func startShuffle() {
        guard phase == .idle || phase == .collapse else { return }
        phase = .shuffle
        shuffleStart = now()
        impactHaptic.impactOccurred(intensity: 0.5)
        after(reduceMotion ? 0.2 : 1.45) { $0.spread() }
    }

    private func spread() {
        phase = .spread
        let t = now()
        wheelAngle = -Double(Int.random(in: 0..<count)) * step
        for i in cards.indices {
            let th = norm(Double(i) * step + wheelAngle)
            // Soldan sağa sırayla uçsunlar
            setMode(i, .wheel, now: t, dur: reduceMotion ? 0.3 : 0.75,
                    delay: reduceMotion ? 0 : (th + 180) / 360 * 1.1)
        }
        after(reduceMotion ? 0.35 : 1.85) { m in
            m.phase = .ready
            m.selectionHaptic.prepare()
            m.impactHaptic.prepare()
        }
    }

    func pick(_ i: Int) {
        guard phase == .ready, cards[i].mode == .wheel, picked.count < pickCount else { return }
        velocity = 0
        let c = cards[i]
        cards[i].mode = .picked
        if hotIndex == i { hotIndex = nil }
        let slot = picked.count
        picked.append(DeckPick(id: i, card: c.card, reversed: c.reversed, slot: slot, start: c.pose))
        spawn(x: c.pose.x, y: c.pose.y, n: 22, spread: 2.4)
        impactHaptic.impactOccurred()

        after(0.02) { m in
            guard slot < m.picked.count else { return }
            withAnimation(.spring(response: 0.75, dampingFraction: 0.8)) { m.picked[slot].landed = true }
        }
        if picked.count == pickCount {
            phase = .reveal
            after(0.9) { $0.revealAll() }
        }
    }

    func pickHot() { if let h = hotIndex { pick(h) } }

    func nudge(_ cardsBy: Int) {
        guard phase == .ready else { return }
        velocity = 0
        wheelAngle += Double(cardsBy) * step
    }

    private func revealAll() {
        for k in picked.indices {
            after(Double(k) * 0.48) { m in
                guard k < m.picked.count else { return }
                withAnimation(.spring(response: 0.85, dampingFraction: 0.82)) { m.picked[k].flipped = true }
                m.impactHaptic.impactOccurred(intensity: 0.7)
                m.after(0.38) { m in
                    let c = m.slotCenter(k)
                    m.spawn(x: c.x, y: c.y, n: 34, spread: 3.2)
                }
            }
        }
        after(Double(picked.count) * 0.48 + 0.9) { m in
            m.dropTarget = m.H * 0.42
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) { m.phase = .reading }
        }
    }

    /// Kartları toplayıp yeniden karıştırır (aynı ekranda yeni çekim).
    func again() {
        guard phase == .reading else { return }
        runID += 1
        withAnimation(.easeInOut(duration: 0.35)) { phase = .collapse }
        for k in picked.indices {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { picked[k].flipped = false }
        }
        after(0.5) { m in
            let t = m.now()
            // Seçilen kartları, durdukları yerden Canvas'a geri devret
            for p in m.picked {
                let c = m.slotCenter(p.slot)
                m.cards[p.id].pose = DeckPose(
                    x: c.x, y: c.y, r: 0,
                    s: m.slotScale * Double(m.bigCardSize.width) / Double(m.wheelCardSize.width), o: 1)
            }
            m.picked = []
            m.dropTarget = 0
            for i in m.cards.indices {
                m.setMode(i, .stack, now: t, dur: 0.65, delay: .random(in: 0...0.18))
            }
            m.after(0.95) { m in
                m.assignFaces()
                m.startShuffle()
            }
        }
    }

    // MARK: Hareket

    func dragChanged(_ v: DragGesture.Value) {
        guard phase == .ready else { return }
        if !dragging {
            dragging = true; velocity = 0; moved = 0
            lastX = v.startLocation.x; lastMoveTime = v.time
            selectionHaptic.prepare()
        }
        let x = Double(v.location.x)
        let dx = x - lastX
        let dA = dx / radius * 180 / .pi           // parmak yayı birebir takip etsin
        wheelAngle += dA
        let dtm = max(0.001, v.time.timeIntervalSince(lastMoveTime))
        velocity = max(-1200, min(1200, velocity * 0.6 + (dA / dtm) * 0.4))
        lastX = x; lastMoveTime = v.time; moved += abs(dx)
    }

    func dragEnded(_ v: DragGesture.Value) {
        guard dragging else { return }
        dragging = false
        if moved < 8 {
            velocity = 0
            handleTap(at: v.location)
        } else if Date().timeIntervalSince(lastMoveTime) > 0.09 {
            velocity = 0   // parmak durup bırakıldıysa fırlatma
        }
    }

    private func handleTap(at p: CGPoint) {
        guard phase == .ready else { return }
        let dx = Double(p.x) - W / 2
        let dy = (centerY0 + drop) - Double(p.y)
        let dist = hypot(dx, dy)
        let h = Double(wheelCardSize.height)
        guard dist > radius - h * 0.75, dist < radius + h * 0.9 else { return }
        let ang = atan2(dx, dy) * 180 / .pi
        var best: Int?
        var bestD = step * 1.5
        for c in cards where c.mode == .wheel {
            let th = norm(Double(c.index) * step + wheelAngle)
            let d = abs(norm(th - ang))
            if d < bestD && abs(th) < 80 { bestD = d; best = c.index }
        }
        if let b = best { pick(b) }
    }

    // MARK: Kare güncelleme (Canvas her karede çağırır)

    func step(now t: Double) {
        guard W > 0 else { return }
        let dt = min(0.048, max(0, t - (lastTick ?? t)))
        lastTick = t

        if phase == .ready && !dragging {
            if abs(velocity) > 4 {
                wheelAngle += velocity * dt
                velocity *= pow(friction, dt * 62.5)
            } else {
                velocity = 0
                let target = (wheelAngle / step).rounded() * step   // bir karta otur
                wheelAngle += (target - wheelAngle) * min(1, dt / 0.11)
            }
        }
        drop += (dropTarget - drop) * min(1, dt / 0.2)
        let liftTarget: Double = (phase == .ready || phase == .reveal) ? 1 : 0
        liftAmt += (liftTarget - liftAmt) * min(1, dt / 0.22)
        let glowTarget: Double = [.spread, .ready, .reveal, .reading].contains(phase) ? 1 : 0
        glowAlpha += (glowTarget - glowAlpha) * min(1, dt / 0.8)

        var best: Int?
        var bestA = 999.0
        var order: [(Int, Double)] = []
        order.reserveCapacity(count)

        for i in cards.indices {
            if cards[i].mode == .picked { cards[i].visible = false; continue }
            let (tp, th) = target(i, t)
            var c = cards[i]
            let p = c.from == nil ? 1 : max(0, min(1, (t - c.t0 - c.delay) / c.dur))
            if p >= 1 { c.pose = tp; c.from = nil } else { c.pose = .lerp(c.from!, tp, ease(p)) }
            let z: Double
            if c.mode == .wheel {
                z = 2000 + th * 5          // sağdaki kart soldakinin üstünde
                if abs(th) < bestA { bestA = abs(th); best = i }
                c.visible = !(p >= 1 && abs(th) > 118)
            } else {
                z = 100 + Double(i)
                c.visible = true
            }
            cards[i] = c
            order.append((i, z))
        }
        drawOrder = order.sorted { $0.1 < $1.1 }.map(\.0)

        let want = phase == .ready ? best : nil
        if want != hotIndex {
            if let w = want, hotIndex != nil, dragging || velocity != 0 {
                selectionHaptic.selectionChanged()     // her kart geçişinde "tık"
                let p = cards[w].pose
                spawn(x: p.x, y: p.y - Double(wheelCardSize.height) / 2 - 6, n: 3, spread: 0.9)
            }
            hotIndex = want
        }

        let k = dt * 62.5
        for j in particles.indices.reversed() {
            var q = particles[j]
            q.life += dt
            if q.life > q.max { particles.remove(at: j); continue }
            q.x += q.vx * k; q.y += q.vy * k
            q.vy += 0.02 * k
            let damp = pow(0.985, k)
            q.vx *= damp; q.vy *= damp
            particles[j] = q
        }
    }

    func draw(in ctx: GraphicsContext,
              tint: Color,
              back: GraphicsContext.ResolvedSymbol?,
              hotBack: GraphicsContext.ResolvedSymbol?) {
        guard W > 0 else { return }

        // Yayın arkasındaki ışık (kart başına gölge yerine tek bir ışık)
        if glowAlpha > 0.01 {
            var g = ctx
            g.translateBy(x: W / 2, y: centerY0 + drop - radius)
            g.scaleBy(x: 1, y: 0.5)
            let rr = radius * 1.3
            g.fill(Path(ellipseIn: CGRect(x: -rr, y: -rr, width: rr * 2, height: rr * 2)),
                   with: .radialGradient(
                    Gradient(colors: [tint.opacity(0.38 * glowAlpha),
                                      tint.opacity(0.08 * glowAlpha), .clear]),
                    center: .zero, startRadius: 0, endRadius: rr))
        }

        // Kartlar
        if let back {
            for i in drawOrder {
                let c = cards[i]
                guard c.visible else { continue }
                var g = ctx
                g.opacity = c.pose.o
                g.translateBy(x: c.pose.x, y: c.pose.y)
                g.rotate(by: .degrees(c.pose.r))
                if abs(c.pose.s - 1) > 0.001 { g.scaleBy(x: c.pose.s, y: c.pose.s) }
                g.draw(i == hotIndex ? (hotBack ?? back) : back, at: .zero, anchor: .center)
            }
        }

        // Kıvılcımlar
        if !particles.isEmpty {
            var g = ctx
            g.blendMode = .plusLighter
            for q in particles {
                let color = q.gold ? AstroTheme.gold : tint
                g.fill(Path(ellipseIn: CGRect(x: q.x - q.r, y: q.y - q.r, width: q.r * 2, height: q.r * 2)),
                       with: .color(color.opacity(1 - q.life / q.max)))
            }
        }
    }

    // MARK: İç hesaplar

    private func now() -> Double { Date().timeIntervalSinceReferenceDate }
    private func norm(_ a: Double) -> Double { ((a + 180).truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) - 180 }
    private func ease(_ t: Double) -> Double { 1 - pow(1 - t, 3) }

    private func assignFaces() {
        let order = Array(0..<count).shuffled()
        for k in cards.indices {
            cards[k].card = deck[order[k]]
            cards[k].reversed = allowsReversed && Double.random(in: 0..<1) < 0.3
        }
    }

    private func setMode(_ i: Int, _ mode: DeckSlotCard<Card>.Mode, now t: Double, dur: Double, delay: Double) {
        cards[i].from = cards[i].pose
        cards[i].mode = mode
        cards[i].t0 = t
        cards[i].dur = dur
        cards[i].delay = delay
    }

    private func target(_ i: Int, _ t: Double) -> (DeckPose, Double) {
        let c = cards[i]
        return c.mode == .wheel ? wheelPose(c) : (stackPose(c, t), 0)
    }

    private func stackPose(_ c: DeckSlotCard<Card>, _ t: Double) -> DeckPose {
        var p = DeckPose(x: W / 2 + c.jx, y: H * 0.68 + c.jy, r: c.jr, s: 1, o: 1)
        if phase == .idle && !reduceMotion { p.y += sin(t / 0.9) * 4 }
        if phase == .shuffle && !reduceMotion {
            let e = t - shuffleStart
            let env = sin(.pi * min(1, e / 1.4))
            let big = c.index % 7 == 0 ? 1.0 : 0.1          // her 7 karttan biri dışarı fırlar
            let w = sin(e / 0.12 + Double(c.index) * 1.3)
            p.x += w * env * big * W * 0.3
            p.y += cos(e / 0.15 + Double(c.index)) * env * big * 22
            p.r += w * env * big * 28
        }
        return p
    }

    private func wheelPose(_ c: DeckSlotCard<Card>) -> (DeckPose, Double) {
        let th = norm(Double(c.index) * step + wheelAngle)
        let lift = liftAmt * Double(wheelCardSize.height) * liftFactor * exp(-(th * th) / (2 * liftSigma * liftSigma))
        let rr = radius + lift
        let rad = th * .pi / 180
        return (DeckPose(x: W / 2 + rr * sin(rad), y: centerY0 + drop - rr * cos(rad),
                         r: th, s: 1, o: phase == .reading ? 0.3 : 1), th)
    }

    private func spawn(x: Double, y: Double, n: Int, spread: Double) {
        guard !reduceMotion else { return }
        for _ in 0..<n {
            let a = Double.random(in: 0..<(2 * .pi))
            let v = Double.random(in: 0.4...(spread + 0.4))
            particles.append(DeckParticle(x: x, y: y, vx: cos(a) * v, vy: sin(a) * v - 0.6,
                                          life: 0, max: .random(in: 0.6...1.2),
                                          r: .random(in: 0.6...2.4), gold: .random()))
        }
    }

    /// Gecikmeli iş; "Yeniden çek" sonrası eski zamanlayıcılar iptal olur.
    private func after(_ delay: Double, _ work: @escaping @MainActor (DeckWheelModel<Card>) -> Void) {
        let id = runID
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, self.runID == id else { return }
            work(self)
        }
    }
}
