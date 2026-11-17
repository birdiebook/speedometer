import SwiftUI
import SpeedKit

/// The dial of docs/FORM.md, drawn in its own 340 x 340 space and scaled to the screen (BESLUT B5).
/// Plain values in, so it can be drawn with fake values (see the previews).
struct DialView: View {
    let speed: Double?       // m/s, nil while finding GPS
    let state: TripState
    let maxSpeed: Double     // m/s, 0 until the trip has a max
    let unit: SpeedUnit
    let locationOff: Bool

    private var dial: Dial { Dial(unit: unit) }
    private var findingGPS: Bool { state == .findingGPS }
    private var paused: Bool { state == .paused }

    /// While paused the needle and the number stand on 0 (FORM.md).
    private var shownSpeed: Double? {
        if findingGPS { return nil }
        return paused ? 0 : speed
    }

    private var needleAngle: Double {
        dial.angle(forSpeed: shownSpeed ?? 0)
    }

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 390
            ZStack(alignment: .topLeading) {
                scale
                    .frame(width: Dial.size, height: Dial.size)
                if maxSpeed > 0 { maxMarker }
                needle
                digital
            }
            .frame(width: Dial.size, height: Dial.size)
            .scaleEffect(s, anchor: .topLeading)
            .frame(width: Dial.size * s, height: Dial.size * s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: ticks and labels

    private var scale: some View {
        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in
                for tick in dial.ticks {
                    let outer = Dial.point(radius: 150, angle: tick.angle)
                    let inner = Dial.point(radius: tick.isMajor ? 132 : 141, angle: tick.angle)
                    var path = Path()
                    path.move(to: CGPoint(x: outer.x, y: outer.y))
                    path.addLine(to: CGPoint(x: inner.x, y: inner.y))
                    ctx.stroke(
                        path,
                        with: .color(tick.isMajor ? Theme.primary : Theme.minorTick),
                        style: StrokeStyle(lineWidth: tick.isMajor ? 2.5 : 1.5, lineCap: .round)
                    )
                }
            }
            ForEach(dial.labels, id: \.value) { tick in
                let p = Dial.point(radius: 112, angle: tick.angle)
                Text("\(tick.value)")
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit() // BESLUT B11
                    .foregroundStyle(Theme.label)
                    .position(x: p.x, y: p.y)
            }
        }
    }

    // MARK: max marker, needle, hub

    private var maxMarker: some View {
        let a = dial.angle(forSpeed: maxSpeed)
        let tip = Dial.point(radius: 153, angle: a)
        let b1 = Dial.point(radius: 166, angle: a - 2.2)
        let b2 = Dial.point(radius: 166, angle: a + 2.2)
        return Path { p in
            p.move(to: CGPoint(x: tip.x, y: tip.y))
            p.addLine(to: CGPoint(x: b1.x, y: b1.y))
            p.addLine(to: CGPoint(x: b2.x, y: b2.y))
            p.closeSubpath()
        }
        .fill(Theme.accent)
    }

    private var needle: some View {
        let color = findingGPS ? Theme.minorTick : Theme.primary
        let tail = Dial.point(radius: -20, angle: 0)
        let tip = Dial.point(radius: 140, angle: 0)
        return ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: tail.x, y: tail.y))
                p.addLine(to: CGPoint(x: tip.x, y: tip.y))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: Dial.size, height: Dial.size)
            // Rotates about the hub, the centre of the 340 pt square.
            .rotationEffect(.degrees(needleAngle))
            // BESLUT B5: a short spring on the needle (METOD M2).
            .animation(.spring(duration: 0.35, bounce: 0.15), value: needleAngle)
            Circle().fill(color).frame(width: 16, height: 16)
                .position(x: Dial.center.x, y: Dial.center.y)
            Circle().fill(Theme.background).frame(width: 6, height: 6)
                .position(x: Dial.center.x, y: Dial.center.y)
        }
    }

    // MARK: digital speed and mode line

    private var digital: some View {
        VStack(spacing: 4) {
            Text(Format.speed(shownSpeed, unit: unit))
                .font(.system(size: 64, weight: .semibold))
                .monospacedDigit() // BESLUT B11
                .foregroundStyle(findingGPS || paused ? Theme.dimmed : Theme.primary)
            modeLine
        }
        .frame(width: Dial.size)
        .position(x: Dial.center.x, y: 218 + 47) // top edge 218 pt down the dial (FORM.md)
    }

    @ViewBuilder
    private var modeLine: some View {
        if locationOff {
            // Added with E1: permission denied or restricted.
            Text("LOCATION OFF")
                .font(.system(size: 12, weight: .semibold)).tracking(3)
                .foregroundStyle(Theme.label)
        } else if findingGPS {
            HStack(spacing: 6) {
                Circle().fill(Theme.label).frame(width: 6, height: 6)
                Text("FINDING GPS")
                    .font(.system(size: 12, weight: .medium)).tracking(3)
                    .foregroundStyle(Theme.label)
            }
        } else if paused {
            Text("PAUSED")
                .font(.system(size: 12, weight: .semibold)).tracking(3)
                .foregroundStyle(Theme.accent)
        } else {
            Text(unit.speedHeading)
                .font(.system(size: 12, weight: .medium)).tracking(3)
                .foregroundStyle(Theme.label)
        }
    }
}

#Preview("Riding") {
    DialView(speed: 36 / 3.6, state: .riding, maxSpeed: 45 / 3.6, unit: .metric, locationOff: false)
        .padding().background(Theme.background)
}

#Preview("Paused") {
    DialView(speed: 0.3, state: .paused, maxSpeed: 45 / 3.6, unit: .metric, locationOff: false)
        .padding().background(Theme.background)
}

#Preview("Finding GPS") {
    DialView(speed: nil, state: .findingGPS, maxSpeed: 0, unit: .imperial, locationOff: false)
        .padding().background(Theme.background)
}
