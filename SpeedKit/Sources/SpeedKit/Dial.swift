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

/// The scale geometry (METOD M6, BESLUT B5). Angles are degrees, 0 straight up, clockwise.
public struct Dial: Equatable {
    // METOD M6: 240 degrees, from -120 to +120.
    public static let minAngle: Double = -120
    public static let maxAngle: Double = 120
    // METOD M6: major tick every 10 units with a label, minor every 2.
    public static let majorStep = 10
    public static let minorStep = 2

    // FORM.md (BESLUT B5): the dial square and its centre.
    public static let size: Double = 340
    public static let center = DialPoint(x: 170, y: 170)

    public let unit: SpeedUnit
    public init(unit: SpeedUnit) { self.unit = unit }

    /// Needle angle for a value in displayed units, clamped to the scale (METOD M6).
    public func angle(forValue value: Double) -> Double {
        let f = min(max(value / unit.scaleMax, 0), 1)
        return Dial.minAngle + (Dial.maxAngle - Dial.minAngle) * f
    }

    /// Needle angle for a speed in m/s.
    public func angle(forSpeed metersPerSecond: Double) -> Double {
        angle(forValue: unit.speed(fromMetersPerSecond: metersPerSecond))
    }

    /// All ticks from 0 to the scale end, minor every 2, major every 10.
    public var ticks: [DialTick] {
        let top = Int(unit.scaleMax)
        return stride(from: 0, through: top, by: Dial.minorStep).map { v in
            DialTick(value: v, angle: angle(forValue: Double(v)), isMajor: v % Dial.majorStep == 0)
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
