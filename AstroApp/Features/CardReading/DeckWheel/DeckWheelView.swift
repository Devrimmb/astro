import SwiftUI

// MARK: - Deste stili

/// Her destenin kart arkası görünümü. Çark, karıştırma ve seçim hareketi ortaktır;
/// yalnızca renkler, arka yüz sembolü ve kart oranı desteye göre değişir.
struct DeckStyle {
    var tint: Color               // parıltı, çerçeve, kıvılcım
    var backColors: [Color]       // arka yüz gradyanı (açık → koyu)
    var glyph: String             // arka yüz merkez sembolü
    var aspect: Double = 1.6      // kart boy/en oranı

    /// Tarot — lavanta arka yüz, 400×700 görsellere uyan oran
    static let tarot = DeckStyle(
        tint: AstroTheme.accent,
        backColors: [Color(red: 0.36, green: 0.25, blue: 0.73),
                     Color(red: 0.17, green: 0.11, blue: 0.42),
                     Color(red: 0.11, green: 0.07, blue: 0.31)],
        glyph: "✦",
        aspect: 1.75
    )
}

// MARK: - Çark görünümü

/// Deste çarkı: kartlar karıştırılır, yay şeklinde serilir, kullanıcı kaydırıp
/// dokunarak seçer; seçilen kart yerine süzülüp 3D çevrilir, altında okuma paneli açılır.
///
/// `front` seçilen kartın ön yüzünü, `panel` okuma içeriğini çizer. `onReveal`
/// kart(lar) çevrilip panel açıldığında bir kez çağrılır (günlük hak düşme vb.).
struct DeckWheelView<Card, Front: View, Panel: View>: View {
    @State private var model: DeckWheelModel<Card>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let style: DeckStyle
    private let title: String
    private let subtitle: String
    private let startTitle: String
    private let slotTitles: [String]
    private let cardName: (Card) -> String
    private let front: (Card, CGSize) -> Front
    private let panel: ([DeckPick<Card>], _ reshuffle: @escaping () -> Void) -> Panel
    private let onReveal: ([DeckPick<Card>]) -> Void

    init(deck: [Card],
         pickCount: Int = 1,
         allowsReversed: Bool = false,
         style: DeckStyle,
         title: String = "Kartını Seç",
         subtitle: String = "Zihnini sorunda tut, desteyi masaya ser",
         startTitle: String = "Desteyi karıştır ve ser",
         slotTitles: [String] = [],
         cardName: @escaping (Card) -> String,
         @ViewBuilder front: @escaping (Card, CGSize) -> Front,
         @ViewBuilder panel: @escaping ([DeckPick<Card>], _ reshuffle: @escaping () -> Void) -> Panel,
         onReveal: @escaping ([DeckPick<Card>]) -> Void = { _ in }) {
        _model = State(initialValue: DeckWheelModel(deck: deck, pickCount: pickCount,
                                                    allowsReversed: allowsReversed,
                                                    aspect: style.aspect))
        self.style = style
        self.title = title
        self.subtitle = subtitle
        self.startTitle = startTitle
        self.slotTitles = slotTitles
        self.cardName = cardName
        self.front = front
        self.panel = panel
        self.onReveal = onReveal
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                wheelCanvas

                overlayUI(size)

                ForEach(model.picked) { p in
                    pickedCardView(p)
                }

                if model.phase == .reading {
                    VStack(spacing: 0) {
                        Spacer(minLength: size.height * model.panelTop)
                        DeckReadingPanel {
                            panel(model.picked) { model.again() }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
                }
            }
            .frame(width: size.width, height: size.height)
            .onAppear {
                model.reduceMotion = reduceMotion
                model.layout(size)
            }
            .onChange(of: size) { _, new in model.layout(new) }
            .onChange(of: reduceMotion) { _, new in model.reduceMotion = new }
            .onChange(of: model.phase) { _, new in
                if new == .reading { onReveal(model.picked) }
            }
        }
    }

    // MARK: Çark (tek Canvas)

    private var wheelCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, _ in
                model.step(now: timeline.date.timeIntervalSinceReferenceDate)
                model.draw(in: ctx, tint: style.tint,
                           back: ctx.resolveSymbol(id: 0),
                           hotBack: ctx.resolveSymbol(id: 1))
            } symbols: {
                DeckCardBack(size: model.wheelCardSize, style: style).padding(16).tag(0)
                DeckCardBack(size: model.wheelCardSize, style: style, glow: true).padding(16).tag(1)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { model.dragChanged($0) }
                .onEnded { model.dragEnded($0) }
        )
        .accessibilityElement()
        .accessibilityLabel("Deste, \(model.count) kart")
        .accessibilityHint("Kartları çevirmek için sola veya sağa kaydır")
        .accessibilityAdjustableAction { dir in model.nudge(dir == .increment ? -1 : 1) }
        .accessibilityAction(named: "Ortadaki kartı seç") { model.pickHot() }
    }

    // MARK: Üst yazılar ve düğmeler

    @ViewBuilder
    private func overlayUI(_ size: CGSize) -> some View {
        let W = size.width, H = size.height

        VStack(spacing: 0) {
            Text(style.glyph)
                .font(.system(size: 40))
                .foregroundStyle(style.tint)
                .shadow(color: style.tint.opacity(0.9), radius: 16)
            Text(title)
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .padding(.top, 14)
                .padding(.bottom, 8)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AstroTheme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .opacity(model.isPicking ? 0 : 1)
        .offset(y: model.isPicking ? -12 : 0)
        .animation(.easeOut(duration: 0.45), value: model.isPicking)
        .position(x: W / 2, y: H * 0.29)
        .allowsHitTesting(false)

        if let text = model.counterText {
            Text(text)
                .font(.footnote)
                .foregroundStyle(AstroTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .position(x: W / 2, y: H * 0.53)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: text)
                .allowsHitTesting(false)
        }

        if model.pickCount > 1 {
            ForEach(0..<model.pickCount, id: \.self) { j in
                let landed = model.picked.contains { $0.slot == j && $0.landed }
                let c = model.slotCenter(j)
                Text(j < slotTitles.count ? slotTitles[j] : "")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(AstroTheme.gold)
                    .opacity(landed ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: landed)
                    .position(x: c.x, y: c.y + model.bigCardSize.height * model.slotScale / 2 + 18)
                    .allowsHitTesting(false)
            }
        }

        if model.showsStartButton {
            Button { model.startShuffle() } label: {
                Text(startTitle).glassButton()
            }
            .position(x: W / 2, y: H * 0.88)
            .transition(.opacity)
        }
    }

    // MARK: Seçilen kart

    private func pickedCardView(_ p: DeckPick<Card>) -> some View {
        let startScale = model.wheelCardSize.width / model.bigCardSize.width
        let target = model.slotCenter(p.slot)
        return DeckFlipCard(angle: p.flipped ? 180 : 0,
                            size: model.bigCardSize,
                            style: style,
                            reversed: p.reversed,
                            allowSheen: !reduceMotion) {
            front(p.card, model.bigCardSize)
        }
        .frame(width: model.bigCardSize.width, height: model.bigCardSize.height)
        .scaleEffect(p.landed ? CGFloat(model.slotScale) : startScale)
        .rotationEffect(.degrees(p.landed ? 0 : p.start.r))
        .position(p.landed ? target : CGPoint(x: p.start.x, y: p.start.y))
        .zIndex(10 + Double(p.slot))
        .allowsHitTesting(false)
        .accessibilityLabel(p.flipped ? "\(cardName(p.card))\(p.reversed ? ", ters" : "")" : "Seçilen kart")
    }
}

// MARK: - Kart arkası (çarkta Canvas sembolü olarak, seçilince büyük hali kullanılır)

struct DeckCardBack: View {
    var size: CGSize
    var style: DeckStyle
    var glow: Bool = false

    var body: some View {
        let w = size.width, h = size.height
        let shape = RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
        let light = style.backColors.first ?? style.tint
        ZStack {
            shape.fill(LinearGradient(colors: style.backColors,
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
            RadialGradient(colors: [style.tint.opacity(0.22), .clear],
                           center: .center, startRadius: 0, endRadius: w * 0.45)
                .clipShape(shape)
            RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                .strokeBorder(style.tint.opacity(0.38), lineWidth: 1)
                .padding(w * 0.07)
            Text(style.glyph)
                .font(.system(size: w * 0.32))
                .foregroundStyle(style.tint.opacity(0.9))
                .shadow(color: style.tint.opacity(0.9), radius: w * 0.06)
            Text("✧")
                .font(.system(size: w * 0.12))
                .foregroundStyle(style.tint.opacity(0.8))
                .offset(x: w * 0.14, y: -h * 0.27)
            Text("✧")
                .font(.system(size: w * 0.12))
                .foregroundStyle(style.tint.opacity(0.8))
                .offset(x: -w * 0.14, y: h * 0.27)
            shape.strokeBorder(glow ? .white.opacity(0.85) : style.tint.opacity(0.6),
                               lineWidth: max(1, w * 0.018))
        }
        .frame(width: w, height: h)
        .shadow(color: glow ? style.tint.opacity(0.95) : light.opacity(0.0), radius: glow ? w * 0.14 : 0)
    }
}

// MARK: - 3D çevrilen kart (Animatable: yüz değişimi tam 90°'de olur)

struct DeckFlipCard<Front: View>: View, Animatable {
    var angle: Double
    let size: CGSize
    let style: DeckStyle
    let reversed: Bool
    var allowSheen: Bool = true
    @ViewBuilder let front: () -> Front

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size.width * 0.08, style: .continuous)
        ZStack {
            DeckCardBack(size: size, style: style)
                .opacity(angle < 90 ? 1 : 0)
            front()
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(reversed ? 180 : 0))
                .overlay {
                    if allowSheen && angle > 179.5 {
                        DeckSheen().clipShape(shape)
                    }
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(angle >= 90 ? 1 : 0)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

/// Açılan kartın üstünden geçen altın parıltı
struct DeckSheen: View {
    @State private var sweep = false

    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [.clear, Color(white: 1, opacity: 0.32), .clear],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: geo.size.width * 0.45, height: geo.size.height * 1.6)
                .rotationEffect(.degrees(20))
                .offset(x: sweep ? geo.size.width * 1.2 : -geo.size.width * 0.7,
                        y: -geo.size.height * 0.3)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).delay(0.6).repeatForever(autoreverses: false)) {
                sweep = true
            }
        }
    }
}

// MARK: - Okuma paneli kabuğu

/// Alttan yükselen cam panel; içeriği kaydırılabilir. İçerik desteye göre değişir.
struct DeckReadingPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            content()
                .padding(22)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AstroTheme.backgroundMid.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AstroTheme.accent.opacity(0.24), lineWidth: 1))
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: 36, height: 4)
                        .padding(.top, 8)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
