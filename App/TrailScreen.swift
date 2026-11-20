import SwiftUI
import SpeedKit

/// The trail page (BESLUT B16): this ride as a line coloured by speed on an empty background, north up, no map.
/// Plain values in, so it can be drawn with a made-up trail. A finger on the line shows the speed, distance and time
/// at that spot (METOD M10). Measurements in docs/FORM.md.
struct TrailScreen: View {
    let trail: Trail
    let trip: Trip
    let unit: SpeedUnit
    /// Debug screenshots only: start with this point selected.
    var initialSelection: Int? = nil

    @State private var selection: Int?

    // FORM.md: the line, the air around it and the faded part after a finger.
    private static let lineWidth: CGFloat = 4
    private static let inset: Double = 12
    private static let fadedOpacity: Double = 0.28
    /// The triangle and the number reach this far from the max point.
    private static let markerReach: Double = 46

    private var hasTrail: Bool { trail.points.count >= 2 && trip.maxSpeed > 0 }

    /// The selected point, kept inside the trail if it was thinned meanwhile (METOD M9).
    private var selectedIndex: Int? {
        guard let s = selection, !trail.points.isEmpty else { return nil }
        return min(max(s, 0), trail.points.count - 1)
    }

    private var selectedPoint: TrailPoint? { selectedIndex.map { trail.points[$0] } }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 28)
            if hasTrail {
                GeometryReader { geo in
                    trailArea(size: geo.size)
                }
                .padding(.vertical, 16)
                legend
            } else {
                Spacer()
                Text("Your trail appears here once you ride.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.label)
                Spacer()
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if selection == nil { selection = initialSelection }
        }
    }

    // MARK: header and legend

    private var header: some View {
        let point = selectedPoint
        let distance = point?.distance ?? trip.distance
        let time = point?.time ?? trip.movingTime
        return HStack(alignment: .firstTextBaseline) {
            Text("TRAIL")
                .font(.system(size: 12, weight: .medium)).tracking(1.5)
                .foregroundStyle(Theme.label)
            Spacer()
            Text("\(Format.distance(distance, unit: unit)) \(unit.distanceSuffix) · \(Format.duration(time))")
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit() // BESLUT B11
                .foregroundStyle(point == nil ? Theme.label : Theme.primary)
        }
    }

    private var legend: some View {
        let fraction = selectedPoint.map { min(max($0.speed / trip.maxSpeed, 0), 1) }
        return VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: Theme.trail, startPoint: .leading, endPoint: .trailing))
                        .frame(height: 4)
                    if let f = fraction {
                        Capsule()
                            .fill(Theme.primary)
                            .frame(width: 3, height: 14)
                            .offset(x: CGFloat(f) * (geo.size.width - 3))
                    }
                }
                .frame(width: geo.size.width, height: 14)
            }
            .frame(height: 14)
            HStack {
                Text("0")
                Spacer()
                Text("\(Format.speed(trip.maxSpeed, unit: unit)) \(unit.speedSuffix)")
            }
            .font(.system(size: 12, weight: .medium))
            .monospacedDigit() // BESLUT B11
            .foregroundStyle(Theme.label)
        }
    }

    // MARK: the trail

    @ViewBuilder
    private func trailArea(size: CGSize) -> some View {
        let layout = TrailLayout(trail: trail, topSpeed: trip.maxSpeed,
                                 width: Double(size.width), height: Double(size.height), inset: TrailScreen.inset)
        let selected = selectedIndex
        ZStack(alignment: .topLeading) {
            Canvas { context, canvasSize in
                draw(layout, selected: selected, size: canvasSize, in: context)
            }
            if let s = selected {
                bubble(for: trail.points[s])
                    .position(bubblePosition(layout.points[s], size: size))
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        // METOD M10: the finger picks the closest point; lifting it puts the page back.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    selection = layout.nearestIndex(to: TrailXY(x: Double(value.location.x),
                                                                y: Double(value.location.y)))
                }
                .onEnded { _ in selection = nil }
        )
        .accessibilityElement()
        .accessibilityLabel("Trail of this ride, coloured by speed")
    }

    private func cg(_ p: TrailXY) -> CGPoint { CGPoint(x: p.x, y: p.y) }

    private func draw(_ layout: TrailLayout, selected: Int?, size: CGSize, in context: GraphicsContext) {
        guard let full = layout.fullRange else { return }
        let last = full.upperBound
        let cut = selected ?? last
        var faded = context
        faded.opacity = TrailScreen.fadedOpacity
        strokeTrail(layout, range: 0...cut, in: context)
        if cut < last {
            strokeTrail(layout, range: cut...last, in: faded)
        }

        // Start: a ring (FORM.md).
        let start = cg(layout.points[0])
        let ring = Path(ellipseIn: CGRect(x: start.x - 4.5, y: start.y - 4.5, width: 9, height: 9))
        context.fill(ring, with: .color(Theme.background))
        context.stroke(ring, with: .color(Theme.label), lineWidth: 2)

        // End, or where you are now: a dot with an edge in the background colour.
        let endContext = cut < last ? faded : context
        let end = cg(layout.points[last])
        let dot = Path(ellipseIn: CGRect(x: end.x - 5, y: end.y - 5, width: 10, height: 10))
        endContext.stroke(dot, with: .color(Theme.background), lineWidth: 4)
        endContext.fill(dot, with: .color(Theme.primary))

        // Max: the dial's orange triangle pointing at the spot across the line, with the number beyond it.
        if let m = layout.maxIndex {
            let p = cg(layout.points[m])
            let d = layout.markerDirection(at: m, reach: TrailScreen.markerReach)
            let n = CGPoint(x: d.x, y: d.y)
            let across = CGPoint(x: -n.y, y: n.x)
            var triangle = Path()
            triangle.move(to: CGPoint(x: p.x + n.x * 9, y: p.y + n.y * 9))
            triangle.addLine(to: CGPoint(x: p.x + n.x * 21 + across.x * 5.5, y: p.y + n.y * 21 + across.y * 5.5))
            triangle.addLine(to: CGPoint(x: p.x + n.x * 21 - across.x * 5.5, y: p.y + n.y * 21 - across.y * 5.5))
            triangle.closeSubpath()
            context.fill(triangle, with: .color(Theme.accent))
            let label = Text(Format.speed(trip.maxSpeed, unit: unit))
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.accent)
            let anchor: UnitPoint = abs(n.x) >= abs(n.y) ? (n.x > 0 ? .leading : .trailing) : (n.y < 0 ? .bottom : .top)
            context.draw(label, at: CGPoint(x: p.x + n.x * 25, y: p.y + n.y * 25), anchor: anchor)
        }

        // The finger: a ring with the colour of that spot inside.
        if let s = selected {
            let p = cg(layout.points[s])
            let outer = Path(ellipseIn: CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20))
            context.fill(outer, with: .color(Theme.background))
            context.stroke(outer, with: .color(Theme.primary), lineWidth: 2.5)
            let level = TrailLayout.level(speed: trail.points[s].speed, top: trip.maxSpeed)
            let inner = Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9))
            context.fill(inner, with: .color(Theme.trail[level]))
        }
    }

    private func strokeTrail(_ layout: TrailLayout, range: ClosedRange<Int>, in context: GraphicsContext) {
        // METOD M9: a gap is a straight dotted line.
        for k in layout.gaps(in: range) {
            var path = Path()
            path.move(to: cg(layout.points[k - 1]))
            path.addLine(to: cg(layout.points[k]))
            context.stroke(path, with: .color(Theme.minorTick),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 6]))
        }
        // METOD M10: one path per run of the same colour step.
        for run in layout.runs(in: range) {
            var path = Path()
            path.move(to: cg(layout.points[run.range.lowerBound]))
            for i in (run.range.lowerBound + 1)...run.range.upperBound {
                path.addLine(to: cg(layout.points[i]))
            }
            context.stroke(path, with: .color(Theme.trail[run.level]),
                           style: StrokeStyle(lineWidth: TrailScreen.lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: the bubble

    private func bubble(for point: TrailPoint) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(Format.speed(point.speed, unit: unit))
                .font(.system(size: 19, weight: .semibold))
                .monospacedDigit() // BESLUT B11
            Text(unit.speedSuffix)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.background)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.primary, in: RoundedRectangle(cornerRadius: 10))
        .fixedSize()
        .allowsHitTesting(false)
    }

    /// Above the point, or below it near the top edge; never past the sides.
    private func bubblePosition(_ p: TrailXY, size: CGSize) -> CGPoint {
        let halfWidth: CGFloat = 46
        let x = min(max(CGFloat(p.x), halfWidth), max(size.width - halfWidth, halfWidth))
        let y = CGFloat(p.y) < 52 ? CGFloat(p.y) + 36 : CGFloat(p.y) - 36
        return CGPoint(x: x, y: y)
    }
}

#Preview("Trail") {
    TrailScreen(trail: DemoTrail.engine.trail, trip: DemoTrail.engine.trip, unit: .metric)
}

#Preview("Finger on the line") {
    TrailScreen(trail: DemoTrail.engine.trail, trip: DemoTrail.engine.trip, unit: .metric,
                initialSelection: DemoTrail.fingerIndex)
}

#Preview("No trail yet") {
    TrailScreen(trail: Trail(), trip: Trip(), unit: .metric)
}
