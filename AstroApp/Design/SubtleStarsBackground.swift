import SwiftUI

struct SubtleStarsBackground: View {
    var body: some View {
        ZStack {
            AstroTheme.backgroundGradient
                .ignoresSafeArea()

            Canvas { context, size in
                // Seed-based rastgele yıldızlar — her frame aynı
                var rng = StableRNG(seed: 42)
                let count = 80

                for _ in 0..<count {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let radius = CGFloat.random(in: 0.3...1.2, using: &rng)
                    let opacity = Double.random(in: 0.15...0.45, using: &rng)

                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Circle().path(in: rect), with: .color(.white.opacity(opacity)))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

private struct StableRNG: RandomNumberGenerator {
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
