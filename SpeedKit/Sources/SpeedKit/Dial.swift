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
/// The scale is fixed and drawn in km/h: a number every 10 up to 100 and every 20 up to 260, with the gaps narrowing
/// as the speed rises. mph numbers stand where the same speed stands. Only the part up to `top` is lit; the next
/// numbers light up when the trip gets there, like a Saab's night panel, and nothing that shows ever moves.
public struct Dial: Equatable {
    // METOD M6: 240 degrees, from -120 to +120.
    public static let minAngle: Double = -120
    public static let maxAngle: Double = 120
    // METOD M6: a new number fades in over this long when the trip passes the lit part.
    public static let revealDuration: TimeInterval = 0.6

    // FORM.md (BESLUT B5): the dial square and its centre.
    public static let size: Double = 340
    public static let center = DialPoint(x: 170, y: 170)

    // METOD M6: in km/h a number every 10 up to 100, each ten 17 degrees at first and evenly narrower down to 15;
    // then every 20 up to 260, each twenty 11 degrees at first and evenly narrower down to 9. Together 240 degrees.
    static let tens = (step: 10, upTo: 100, first: 17.0, last: 15.0)
    static let twenties = (step: 20, upTo: 260, first: 11.0, last: 9.0)

    /// The numbers of the km/h scale with their angles; the needle goes straight between neighbours.
    static let anchors: [(kmh: Double, angle: Double)] = {
        let zones = [Dial.tens, Dial.twenties]
        var list: [(kmh: Double, angle: Double)] = [(0, Dial.minAngle)]
        var angle = Dial.minAngle
        var kmh = 0
        for zone in zones {
            let count = (zone.upTo - kmh) / zone.step
            for k in 0..<count {
                angle += zone.first + (zone.last - zone.first) * Double(k) / Double(count - 1)
                kmh += zone.step
                list.append((kmh: Double(kmh), angle: angle))
            }
        }
        list[list.count - 1].angle = Dial.maxAngle // the sum is 240 degrees; no rounding left over at the end
        return list
    }()

    public let unit: SpeedUnit
    /// BESLUT B16: the highest number lit so far.
    public let top: Int

    /// BESLUT B16: lit up to the smallest number that holds `metersPerSecond` (the trip's max, or the speed if
    /// higher), and never less than the first top.
    public init(unit: SpeedUnit, fitting metersPerSecond: Double = 0) {
        self.unit = unit
        self.top = Dial.top(fitting: unit.speed(fromMetersPerSecond: metersPerSecond), unit: unit)
    }

    /// METOD M6: the numbers on the dial: every 10 up to 100 km/h and every 20 up to 260; in mph every 10 up to 60
    /// and every 20 up to 160.
    public static func numbers(_ unit: SpeedUnit) -> [Int] {
        switch unit {
        case .metric:
            return anchors.map { Int($0.kmh) }
        case .imperial:
            return Array(stride(from: 0, through: 60, by: 10)) + Array(stride(from: 80, through: 160, by: 20))
        }
    }

    /// METOD M6: lit from the start: up to 100 km/h or 60 mph.
    public static func firstTop(_ unit: SpeedUnit) -> Int { unit == .metric ? 100 : 60 }

    // METOD M6: minor ticks every 2 up to 100 km/h and every 5 above; in mph every 2 up to 60 and every 5 above.
    static func tickSteps(_ unit: SpeedUnit) -> [(upTo: Int, step: Int)] {
        unit == .metric ? [(100, 2), (260, 5)] : [(60, 2), (160, 5)]
    }

    /// The smallest number from the first top on that holds `value` (displayed units); the last number above that.
    static func top(fitting value: Double, unit: SpeedUnit) -> Int {
        let numbers = numbers(unit)
        guard !value.isNaN else { return firstTop(unit) }
        return numbers.first { $0 >= firstTop(unit) && Double($0) >= value } ?? numbers[numbers.count - 1]
    }

    /// Needle angle for a value in displayed units (METOD M6): straight between the neighbouring numbers of the km/h
    /// scale. Past 260 km/h the needle stops at the end; the big number still shows the speed.
    public func angle(forValue value: Double) -> Double {
        Dial.angle(kmh: SpeedUnit.metric.speed(fromMetersPerSecond: value * unit.metersPerSecondPerUnit))
    }

    /// Needle angle for a speed in m/s.
    public func angle(forSpeed metersPerSecond: Double) -> Double {
        Dial.angle(kmh: SpeedUnit.metric.speed(fromMetersPerSecond: metersPerSecond))
    }

    static func angle(kmh v: Double) -> Double {
        guard v > 0 else { return minAngle }
        for i in 1..<anchors.count where v <= anchors[i].kmh {
            let (a, b) = (anchors[i - 1], anchors[i])
            return a.angle + (b.angle - a.angle) * (v - a.kmh) / (b.kmh - a.kmh)
        }
        return maxAngle
    }

    /// The lit ticks, from 0 to the top; the numbered ones are major. Each keeps its angle whatever the top.
    public var ticks: [DialTick] {
        var values: [Int] = []
        var v = 0
        for band in Dial.tickSteps(unit) {
            while v < band.upTo {
                values.append(v)
                v += band.step
            }
        }
        values.append(v)
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
