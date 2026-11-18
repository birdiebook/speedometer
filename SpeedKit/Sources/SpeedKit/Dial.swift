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
///
/// The scale is fixed: wide at low speeds and narrower towards the end, so it holds every speed and nothing on it ever
/// moves. Only the part up to `top` is lit; higher numbers light up when the trip gets there, like a Saab's night panel.
public struct Dial: Equatable {
    // METOD M6: 240 degrees, from -120 to +120.
    public static let minAngle: Double = -120
    public static let maxAngle: Double = 120
    // METOD M6: new numbers fade in over this long when the trip passes the lit part.
    public static let revealDuration: TimeInterval = 0.6

    // FORM.md (BESLUT B5): the dial square and its centre.
    public static let size: Double = 340
    public static let center = DialPoint(x: 170, y: 170)

    // METOD M6: minor ticks every 2 up to 60, every 5 up to 100, every 10 up to 200 and every 50 up to 500, where the
    // ticks end. The same in km/h and mph.
    static let tickSteps: [(upTo: Int, step: Int)] = [(60, 2), (100, 5), (200, 10), (500, 50)]
    static let lastTick = 500

    public let unit: SpeedUnit
    /// BESLUT B16: the highest number lit so far.
    public let top: Int

    /// BESLUT B16: lit up to the smallest number that holds `metersPerSecond` (the trip's max, or the speed if
    /// higher), and never less than the first top.
    public init(unit: SpeedUnit, fitting metersPerSecond: Double = 0) {
        self.unit = unit
        self.top = Dial.top(fitting: unit.speed(fromMetersPerSecond: metersPerSecond), unit: unit)
    }

    /// METOD M6: the speed straight up, half way along the scale: 60 km/h or 40 mph.
    public static func middle(_ unit: SpeedUnit) -> Double { unit == .metric ? 60 : 40 }

    /// METOD M6: the numbers on the dial.
    public static func numbers(_ unit: SpeedUnit) -> [Int] {
        unit == .metric ? [0, 10, 20, 30, 40, 50, 60, 80, 100, 200, 500] : [0, 10, 20, 30, 40, 50, 60, 100, 200, 500]
    }

    /// METOD M6: lit from the start: up to 100 km/h or 60 mph.
    public static func firstTop(_ unit: SpeedUnit) -> Int { unit == .metric ? 100 : 60 }

    /// The smallest number from the first top on that holds `value` (displayed units); 500 above that.
    static func top(fitting value: Double, unit: SpeedUnit) -> Int {
        guard !value.isNaN else { return firstTop(unit) }
        let stops = numbers(unit).filter { $0 >= firstTop(unit) }
        return stops.first { Double($0) >= value } ?? lastTick
    }

    /// Needle angle for a value in displayed units (METOD M6): −120° + 240° · (2/π) · atan(value / middle). It never
    /// reaches the end, so there is no ceiling.
    public func angle(forValue value: Double) -> Double {
        let f = (2 / Double.pi) * atan(max(value, 0) / Dial.middle(unit))
        return Dial.minAngle + (Dial.maxAngle - Dial.minAngle) * f
    }

    /// Needle angle for a speed in m/s.
    public func angle(forSpeed metersPerSecond: Double) -> Double {
        angle(forValue: unit.speed(fromMetersPerSecond: metersPerSecond))
    }

    /// The lit ticks, from 0 to the top; the numbered ones are major. Each keeps its angle whatever the top.
    public var ticks: [DialTick] {
        var values: [Int] = []
        var v = 0
        for band in Dial.tickSteps {
            while v < band.upTo {
                values.append(v)
                v += band.step
            }
        }
        values.append(Dial.lastTick)
        let numbers = Set(Dial.numbers(unit))
        return values.filter { $0 <= top }.map { v in
            DialTick(value: v, angle: angle(forValue: Double(v)), isMajor: numbers.contains(v))
        }
    }

    /// The lit numbers.
    public var labels: [DialTick] { ticks.filter { $0.isMajor } }

    /// FORM.md: x = 170 + r sin(theta), y = 170 - r cos(theta). Theta in degrees.
    public static func point(radius r: Double, angle degrees: Double) -> DialPoint {
        let t = degrees * Double.pi / 180
        return DialPoint(x: center.x + r * sin(t), y: center.y - r * cos(t))
    }
}
