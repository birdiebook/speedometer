import Foundation

/// A point in the dial's own coordinate space (FORM.md: 340 x 340, centre at 170, 170).
public struct DialPoint: Equatable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct DialTick: Equatable {
    /// Value in displayed units (km/h or mph).
    public var value: Int
    /// Degrees, 0 straight up, clockwise.
    public var angle: Double
    public var isMajor: Bool
}

/// The scale geometry (METOD M6, BESLUT B5, B16). Angles are degrees, 0 straight up, clockwise.
public struct Dial: Equatable {
    // METOD M6: 240 degrees, from -120 to +120.
    public static let minAngle: Double = -120
    public static let maxAngle: Double = 120
    // METOD M6: on the first scale a major tick every 10 units with a label, a minor one every 2. Both grow with
    // the scale, so the ticks keep their angles and only the labels change.
    public static let majorStep = 10
    public static let minorStep = 2

    // FORM.md (BESLUT B5): the dial square and its centre.
    public static let size: Double = 340
    public static let center = DialPoint(x: 170, y: 170)

    public let unit: SpeedUnit
    /// METOD M6: how many times the first scale this one is: 1, 2, 3, 4, 6, 8, 12, 16, …
    public let factor: Int

    /// BESLUT B16: the smallest scale that holds `metersPerSecond` (the trip's max, or the speed if higher).
    /// The first scale when nothing is given.
    public init(unit: SpeedUnit, fitting metersPerSecond: Double = 0) {
        self.unit = unit
        self.factor = Dial.factor(fitting: unit.speed(fromMetersPerSecond: metersPerSecond), base: unit.baseScaleMax)
    }

    /// The scale's end in displayed units: 60, 120, 180, 240, 360, … km/h or 40, 80, 120, 160, 240, … mph.
    public var scaleMax: Double { unit.baseScaleMax * Double(factor) }

    /// METOD M6: the smallest step of 1, 2, 3, 4, 6, 8, 12, 16, … (after 3 each one is the one two places back,
    /// doubled) whose scale reaches `value`, in displayed units. No ceiling.
    static func factor(fitting value: Double, base: Double) -> Int {
        guard value.isFinite else { return 1 }
        var factor = 1
        var next = (2, 3)
        while base * Double(factor) < value {
            factor = next.0
            next = (next.1, next.0 * 2)
        }
        return factor
    }

    /// Needle angle for a value in displayed units, clamped to the scale (METOD M6).
    public func angle(forValue value: Double) -> Double {
        let f = min(max(value / scaleMax, 0), 1)
        return Dial.minAngle + (Dial.maxAngle - Dial.minAngle) * f
    }

    /// Needle angle for a speed in m/s.
    public func angle(forSpeed metersPerSecond: Double) -> Double {
        angle(forValue: unit.speed(fromMetersPerSecond: metersPerSecond))
    }

    /// All ticks from 0 to the scale's end: on the first scale minor every 2 and major every 10, on the others the
    /// same times the factor, so there are always as many and at the same angles.
    public var ticks: [DialTick] {
        let top = Int(scaleMax)
        let minor = Dial.minorStep * factor
        let major = Dial.majorStep * factor
        return stride(from: 0, through: top, by: minor).map { v in
            DialTick(value: v, angle: angle(forValue: Double(v)), isMajor: v % major == 0)
        }
    }

    /// The labelled ticks.
    public var labels: [DialTick] { ticks.filter { $0.isMajor } }

    /// FORM.md: x = 170 + r sin(theta), y = 170 - r cos(theta). Theta in degrees.
    public static func point(radius r: Double, angle degrees: Double) -> DialPoint {
        let t = degrees * Double.pi / 180
        return DialPoint(x: center.x + r * sin(t), y: center.y - r * cos(t))
    }
}
