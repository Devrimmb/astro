import SwiftUI

/// Yaşayan çarkın görünümü: `TimelineView` + tek `Canvas`. Fizik ve çizim
/// `LiveChartWheelModel`'de; bu görünüm yalnızca kareyi ister, dokunmayı iletir
/// ve hareket bitince zaman çizgisini durdurur (pil).
struct LiveChartWheelView: View {
    let model: LiveChartWheelModel
    let size: CGFloat
    var onSelectPlanet: ((Planet) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var paused = false

    var body: some View {
        TimelineView(.animation(paused: paused)) { timeline in
            Canvas { ctx, canvasSize in
                let now = timeline.date.timeIntervalSinceReferenceDate
                model.step(now: now)
                model.draw(in: ctx, size: canvasSize, now: now)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            guard model.mode == .result, let planet = model.planet(at: location, size: size) else { return }
            onSelectPlanet?(planet)
        }
        .onAppear { model.reduceMotion = reduceMotion }
        .onChange(of: reduceMotion) { _, new in model.reduceMotion = new }
        .task(id: model.revision) {
            // Her dış değişimde uyan; yaylar oturunca durdur
            paused = false
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                if Task.isCancelled { return }
                if !model.isMoving {
                    paused = true
                    return
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Doğum haritası çarkı")
        .accessibilityHint(model.mode == .result ? "Bir gezegene dokununca açıları vurgulanır" : "")
    }
}
