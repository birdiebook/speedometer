import Foundation

/// METOD M2: how the needle moves to a new speed instead of jumping to it.
///
/// Each change is spread evenly over about one GPS interval, with soft corners. The app adds overlapping changes
/// together (SwiftUI runs animations that do not merge side by side and sums them). With an even acceleration the
/// GPS steps are about equal, so the needle then turns at an even pace between samples, like a car's.
public enum NeedleGlide {
    // METOD M2: a change is spread evenly over about one GPS interval...
    public static let interval: TimeInterval = 1.0
    // METOD M2: ...and eases in and out over this long, so the motion has no kinks.
    public static let softening: TimeInterval = 0.4

    /// The whole glide of one change, in seconds.
    public static var duration: TimeInterval { interval + softening }

    /// The share of a change the needle has covered `t` seconds after it: 0 up to the start, 1 from `duration` on.
    /// Its rate rises evenly to 1/interval over `softening`, holds, and falls evenly to 0 (a trapezoid), so it never
    /// goes past the new value or back. Copies one interval apart add up to an even ramp.
    public static func progress(_ t: TimeInterval) -> Double {
        let a = softening
        let d = duration
        if t <= 0 { return 0 }
        if t >= d { return 1 }
        if t < a { return t * t / (2 * a * interval) }
        if t <= interval { return (t - a / 2) / interval }
        let left = d - t
        return 1 - left * left / (2 * a * interval)
    }
}
