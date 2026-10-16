import SwiftUI

/// Çark çizimlerinin ortak geometrisi. Dilimler `Path.addArc` yerine polyline ile
/// üretilir: SwiftUI'da `clockwise` bayrağı ters çalıştığı için 30°'lik dilim
/// 330° olarak dolabiliyordu (12 dilim üst üste → bej bant).
enum WheelGeometry {
    /// `pointOnCircle` ile aynı konvansiyon: x = cx + r·cos, y = cy − r·sin
    static func point(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let rad = angle.radians
        return CGPoint(
            x: center.x + radius * CGFloat(Foundation.cos(rad)),
            y: center.y - radius * CGFloat(Foundation.sin(rad))
        )
    }

    /// Halka dilimi — iki açı arasındaki **kısa** yay (|Δ| ≤ 180°) üzerinden.
    static func ringSegment(center: CGPoint, innerRadius: CGFloat, outerRadius: CGFloat,
                            startAngle: Angle, endAngle: Angle, steps: Int = 10) -> Path {
        var delta = (endAngle.degrees - startAngle.degrees).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }

        var path = Path()
        for i in 0...steps {
            let a = Angle(degrees: startAngle.degrees + delta * Double(i) / Double(steps))
            let p = point(center: center, radius: outerRadius, angle: a)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let a = Angle(degrees: startAngle.degrees + delta * Double(i) / Double(steps))
            path.addLine(to: point(center: center, radius: innerRadius, angle: a))
        }
        path.closeSubpath()
        return path
    }
}
