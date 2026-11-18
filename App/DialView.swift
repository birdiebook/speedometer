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
    /// The full screen width in points; FORM.md scales everything with it (390 pt is 1:1).
    var screenWidth: CGFloat = 390
    /// BESLUT B15: PAUSED only once something has been ridden; a new or reset trip shows the unit instead.
    var tripStarted: Bool = true

    /// BESLUT B16: the fixed scale, lit up to the trip's max (or the speed right after a reset).
    private var dial: Dial { Dial(unit: unit, fitting: max(maxSpeed, target)) }
    private var findingGPS: Bool { state == .findingGPS }
    private var paused: Bool { state == .paused }

    /// Where the needle and the number are heading: 0 while paused or finding GPS (FORM.md).
    private var target: Double {
        state == .riding ? (speed ?? 0) : 0
    }

    var body: some View {
        GeometryReader { geo in
            // Scales with the screen, but never wider than the room the screen's margins leave.
            let s = min(screenWidth / 390, geo.size.width / Dial.size)
            ZStack(alignment: .topLeading) {
                scale
                    .frame(width: Dial.size, height: Dial.size)
                if maxSpeed > 0 {
                    MaxMarker(speed: maxSpeed, dial: dial)
                        .animation(.needleGlide, value: maxSpeed)
                }
                // BESLUT B5: the needle glides to each new speed like a car's instead of jumping (METOD M2).
                Needle(speed: target, dial: dial, color: findingGPS ? Theme.minorTick : Theme.primary)
                    .animation(.needleGlide, value: target)
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

    /// The lit part of the fixed scale. When the trip goes past it, the next ticks and numbers fade in at the end and
    /// nothing else moves (BESLUT B16, METOD M6); a reset fades them out again.
    private var scale: some View {
        ZStack(alignment: .topLeading) {
            ForEach(dial.ticks, id: \.value) { tick in
                TickMark(tick: tick)
                    .transition(.opacity)
            }
            ForEach(dial.labels, id: \.value) { tick in
                let p = Dial.point(radius: 112, angle: tick.angle)
                Text("\(tick.value)")
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit() // BESLUT B11
                    .foregroundStyle(Theme.label)
                    .position(x: p.x, y: p.y)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: Dial.revealDuration), value: dial.top)
    }

    // MARK: digital speed and mode line

    private var digital: some View {
        VStack(spacing: 4) {
            GlidingNumber(speed: target, unit: unit, dash: findingGPS, dimmed: findingGPS || paused)
                .animation(.needleGlide, value: target)
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
        } else if paused && tripStarted {
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

/// One tick on the scale (FORM.md).
private struct TickMark: View {
    let tick: DialTick

    var body: some View {
        let outer = Dial.point(radius: 150, angle: tick.angle)
        let inner = Dial.point(radius: tick.isMajor ? 132 : 141, angle: tick.angle)
        Path { p in
            p.move(to: CGPoint(x: outer.x, y: outer.y))
            p.addLine(to: CGPoint(x: inner.x, y: inner.y))
        }
        .stroke(
            tick.isMajor ? Theme.primary : Theme.minorTick,
            style: StrokeStyle(lineWidth: tick.isMajor ? 2.5 : 1.5, lineCap: .round)
        )
    }
}

// MARK: what glides (METOD M2)
//
// The needle, the max marker and the big number glide in speed, so the number always says what the needle points at.

/// The needle and the hub.
private struct Needle: View, Animatable {
    var speed: Double // m/s
    let dial: Dial
    let color: Color

    var animatableData: Double {
        get { speed }
        set { speed = newValue }
    }

    var body: some View {
        let tail = Dial.point(radius: -20, angle: 0)
        let tip = Dial.point(radius: 140, angle: 0)
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: tail.x, y: tail.y))
                p.addLine(to: CGPoint(x: tip.x, y: tip.y))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: Dial.size, height: Dial.size)
            // Rotates about the hub, the centre of the 340 pt square.
            .rotationEffect(.degrees(dial.angle(forSpeed: speed)))
            Circle().fill(color).frame(width: 16, height: 16)
                .position(x: Dial.center.x, y: Dial.center.y)
            Circle().fill(Theme.background).frame(width: 6, height: 6)
                .position(x: Dial.center.x, y: Dial.center.y)
        }
    }
}

/// The orange marker at the trip's max, which the needle pushes ahead of it. Drawn pointing straight up, then turned.
private struct MaxMarker: View, Animatable {
    var speed: Double // m/s
    let dial: Dial

    var animatableData: Double {
        get { speed }
        set { speed = newValue }
    }

    var body: some View {
        let tip = Dial.point(radius: 153, angle: 0)
        let b1 = Dial.point(radius: 166, angle: -2.2)
        let b2 = Dial.point(radius: 166, angle: 2.2)
        Path { p in
            p.move(to: CGPoint(x: tip.x, y: tip.y))
            p.addLine(to: CGPoint(x: b1.x, y: b1.y))
            p.addLine(to: CGPoint(x: b2.x, y: b2.y))
            p.closeSubpath()
        }
        .fill(Theme.accent)
        .frame(width: Dial.size, height: Dial.size)
        .rotationEffect(.degrees(dial.angle(forSpeed: speed)))
    }
}

/// The big number, from the same gliding speed as the needle, so the two always agree: it counts through the values
/// on the way instead of jumping.
private struct GlidingNumber: View, Animatable {
    var speed: Double // m/s
    let unit: SpeedUnit
    /// Finding GPS: the dash instead of a number (FORM.md).
    let dash: Bool
    let dimmed: Bool

    var animatableData: Double {
        get { speed }
        set { speed = newValue }
    }

    var body: some View {
        Text(Format.speed(dash ? nil : speed, unit: unit))
            .font(.system(size: 64, weight: .semibold))
            .monospacedDigit() // BESLUT B11
            .foregroundStyle(dimmed ? Theme.dimmed : Theme.primary)
    }
}

/// METOD M2: each change glides over `NeedleGlide.duration` along `NeedleGlide.progress`. It never merges with a
/// glide that is still running: SwiftUI then runs them side by side and adds them up, so a new GPS sample carries
/// on from where the needle is, and even steps turn into an even motion.
private struct NeedleGlideAnimation: CustomAnimation {
    func animate<V: VectorArithmetic>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? {
        guard time < NeedleGlide.duration else { return nil }
        return value.scaled(by: NeedleGlide.progress(time))
    }
}

private extension Animation {
    /// METOD M2.
    static var needleGlide: Animation { Animation(NeedleGlideAnimation()) }
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

#Preview("High-speed train") {
    DialView(speed: 300 / 3.6, state: .riding, maxSpeed: 320 / 3.6, unit: .metric, locationOff: false)
        .padding().background(Theme.background)
}
