import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var starsOpacity: Double = 0
    @State private var dismissOpacity: Double = 1

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            // Arka plan
            AstroTheme.backgroundGradient
                .ignoresSafeArea()

            // Animasyonlu yıldızlar
            SplashStarsCanvas(opacity: starsOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                Spacer()

                // Dönen halka + Logo
                ZStack {
                    // Dış halka
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    AstroTheme.accent,
                                    AstroTheme.accentSecondary,
                                    AstroTheme.accent.opacity(0.3),
                                    AstroTheme.accent
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(ringRotation))
                        .opacity(ringOpacity)

                    // İkinci halka
                    Circle()
                        .strokeBorder(
                            AstroTheme.accentSecondary.opacity(0.3),
                            lineWidth: 1
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-ringRotation * 0.7))
                        .opacity(ringOpacity)

                    // Logo ikonu
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AstroTheme.accent.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AstroTheme.accent, AstroTheme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: AstroTheme.accent.opacity(0.5), radius: 15)
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Uygulama adı
                VStack(spacing: 8) {
                    Text("AstroApp")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AstroTheme.accent, AstroTheme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(titleOpacity)

                    Text("Yıldızların Rehberliğinde")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AstroTheme.textSecondary)
                        .opacity(subtitleOpacity)
                }

                Spacer()

                // Alt dekoratif çizgi
                RoundedRectangle(cornerRadius: 2)
                    .fill(AstroTheme.accentGradient)
                    .frame(width: 40, height: 3)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 60)
            }
        }
        .opacity(dismissOpacity)
        .task {
            await runAnimation()
        }
    }

    private func runAnimation() async {
        // Yıldızlar belirsin
        withAnimation(.easeIn(duration: 0.4)) {
            starsOpacity = 1
        }

        // Logo giriş
        withAnimation(.spring(duration: 0.7, bounce: 0.3)) {
            logoScale = 1.0
            logoOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(200))

        // Halka belirsin ve dönmeye başlasın
        withAnimation(.easeOut(duration: 0.5)) {
            ringOpacity = 1
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }

        try? await Task.sleep(for: .milliseconds(300))

        // Başlık
        withAnimation(.easeOut(duration: 0.5)) {
            titleOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(200))

        // Alt başlık
        withAnimation(.easeOut(duration: 0.5)) {
            subtitleOpacity = 1
        }

        // Bekle ve kapat
        try? await Task.sleep(for: .milliseconds(1200))

        withAnimation(.easeInOut(duration: 0.4)) {
            dismissOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(450))
        onFinished()
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
