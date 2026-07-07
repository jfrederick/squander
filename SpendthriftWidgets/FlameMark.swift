import SwiftUI

/// Hand-drawn vector flame — the widget's brand mark (echoes the burning-money
/// app icon without shipping a rasterized asset). Two cubic-curve paths in a
/// 100x130 design box: the outer body with a tip leaning right, and a hotter
/// inner core.
struct FlameShape: Shape {
    /// Draws the smaller inner core instead of the outer body.
    var core = false

    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 100 * rect.width, y: rect.minY + y / 130 * rect.height)
        }
        var path = Path()
        if core {
            path.move(to: p(50, 122))
            path.addCurve(to: p(34, 96), control1: p(40, 120), control2: p(34, 108))
            path.addCurve(to: p(48, 62), control1: p(34, 82), control2: p(42, 68))
            path.addCurve(to: p(66, 96), control1: p(56, 70), control2: p(66, 82))
            path.addCurve(to: p(50, 122), control1: p(66, 110), control2: p(58, 120))
        } else {
            path.move(to: p(50, 126))
            path.addCurve(to: p(14, 88), control1: p(30, 124), control2: p(14, 106))
            path.addCurve(to: p(40, 34), control1: p(18, 64), control2: p(38, 52))
            path.addCurve(to: p(58, 4), control1: p(42, 22), control2: p(50, 10))
            path.addCurve(to: p(72, 42), control1: p(64, 14), control2: p(72, 26))
            path.addCurve(to: p(86, 88), control1: p(72, 58), control2: p(86, 70))
            path.addCurve(to: p(50, 126), control1: p(86, 108), control2: p(70, 122))
        }
        path.closeSubpath()
        return path
    }
}

/// The composed flame: red-to-orange body under an orange-to-yellow core.
struct FlameMark: View {
    var body: some View {
        ZStack {
            FlameShape()
                .fill(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
            FlameShape(core: true)
                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
        }
        .aspectRatio(100.0 / 130.0, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
