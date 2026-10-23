import SwiftUI

/// Açılış ekranı: natal çarkın iskeleti yaylanarak yerine oturur, merkezde
/// o günkü Ay evresi, altında serif uygulama adı. Toplam ≈ 1,8 sn.
struct SplashView: View {
    @State private var starsOpacity: Double = 0
    @State private var wheelOpacity: Double = 0
    @State private var wheelRotation: Double = -30
    @State private var wheelScale: CGFloat = 0.86
    @State private var moonOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 8
    @State private var subtitleOpacity: Double = 0
    @State private var dismissOpacity: Double = 1

    private let moonPhase = MoonPhaseCalculator.currentPhase()

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            AstroTheme.backgroundGradient
                .ignoresSafeArea()

            // Aurora — Anasayfa ile aynı iki ışıma
            RadialGradient(colors: [AstroTheme.accent.opacity(0.22), .clear],
                           center: .init(x: 0.5, y: 0.1), startRadius: 0, endRadius: 320)
                .ignoresSafeArea()
            RadialGradient(colors: [AstroTheme.accentSecondary.opacity(0.10), .clear],
                           center: .init(x: 1.05, y: 0.75), startRadius: 0, endRadius: 280)
                .ignoresSafeArea()

            SplashStarsCanvas(opacity: starsOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    WheelSkeleton()
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(wheelRotation))
                        .scaleEffect(wheelScale)
                        .opacity(wheelOpacity)

                    MoonDisc(info: moonPhase, size: 86)
                        .opacity(moonOpacity)
                }

                VStack(spacing: 10) {
                    Text("AstroApp")
                        .font(.system(size: 40, design: .serif))
                        .foregroundStyle(.white)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("YILDIZLARIN REHBERLİĞİNDE")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(2.4)
                        .foregroundStyle(AstroTheme.textTertiary)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                Capsule()
                    .fill(AstroTheme.accentGradient)
                    .frame(width: 36, height: 2)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 56)
            }
        }
        .opacity(dismissOpacity)
        .task { await runAnimation() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("AstroApp açılıyor")
    }

    private func runAnimation() async {
        withAnimation(.easeIn(duration: 0.3)) { starsOpacity = 1 }

        // Çark yerine oturur
        withAnimation(.spring(duration: 0.7, bounce: 0.18)) {
            wheelOpacity = 1
            wheelRotation = 0
            wheelScale = 1
        }

        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.easeOut(duration: 0.5)) { moonOpacity = 1 }

        try? await Task.sleep(for: .milliseconds(170))
        withAnimation(.easeOut(duration: 0.45)) {
            titleOpacity = 1
            titleOffset = 0
        }

        try? await Task.sleep(for: .milliseconds(200))
        withAnimation(.easeOut(duration: 0.4)) { subtitleOpacity = 1 }

        try? await Task.sleep(for: .milliseconds(850))
        withAnimation(.easeInOut(duration: 0.3)) { dismissOpacity = 0 }

        try? await Task.sleep(for: .milliseconds(320))
        onFinished()
    }
}

// MARK: - Çark İskeleti

/// Natal çarkın sadeleştirilmiş hali: element tonlu 12 dilim, ince halkalar,
/// dört köşe ekseni. Ascendant solda — uygulamadaki çarkla aynı oryantasyon.
private struct WheelSkeleton: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2 - 2
            let signInner = outer - 26
            let houseInner = signInner - 34

            for sign in ZodiacSign.allCases {
                let start = Angle(degrees: 180 - Double(sign.rawValue) * 30)
                let end = Angle(degrees: start.degrees - 30)
                let segment = WheelGeometry.ringSegment(center: center, innerRadius: signInner, outerRadius: outer,
                                                        startAngle: start, endAngle: end)
                context.fill(segment, with: .color(AstroTheme.element(sign.element).opacity(0.14)))
                context.stroke(segment, with: .color(.white.opacity(0.10)), lineWidth: 0.5)

                let point = WheelGeometry.point(center: center, radius: (outer + signInner) / 2, angle: .degrees(start.degrees - 15))
                let glyph = Text(sign.glyph)
                    .font(.system(size: 11, design: .serif))
                    .foregroundColor(AstroTheme.element(sign.element).opacity(0.9))
                context.draw(context.resolve(glyph), at: point, anchor: .center)
            }

            for (radius, opacity, width): (CGFloat, Double, CGFloat) in [(outer, 0.22, 0.8), (signInner, 0.18, 0.8), (houseInner, 0.10, 0.5)] {
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)), lineWidth: width)
            }

            // Köşe eksenleri (AC–DC, MC–IC)
            for degrees in [0.0, 90.0] {
                let a = WheelGeometry.point(center: center, radius: signInner, angle: .degrees(degrees))
                let b = WheelGeometry.point(center: center, radius: signInner, angle: .degrees(degrees + 180))
                var axis = Path()
                axis.move(to: a)
                axis.addLine(to: b)
                context.stroke(axis, with: .color(.white.opacity(0.18)), lineWidth: 0.8)
            }
        }
    }
}

// MARK: - Splash Yıldız Canvas

private struct SplashStarsCanvas: View {
    let opacity: Double

    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            var rng = SplashRNG(seed: 77)
            let count = 120

            for i in 0..<count {
                let x = CGFloat.random(in: 0...size.width, using: &rng)
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let baseRadius = CGFloat.random(in: 0.3...1.5, using: &rng)
                let baseOpacity = Double.random(in: 0.1...0.6, using: &rng)

                // Bazı yıldızlar parıldasın
                let shimmer = sin(shimmerPhase + Double(i) * 0.5) * 0.3 + 0.7
                let finalOpacity = baseOpacity * shimmer

                let rect = CGRect(
                    x: x - baseRadius,
                    y: y - baseRadius,
                    width: baseRadius * 2,
                    height: baseRadius * 2
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(finalOpacity))
                )
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                shimmerPhase = .pi * 2
            }
        }
    }
}

private struct SplashRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
