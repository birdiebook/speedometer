import XCTest
@testable import SpeedKit

final class DialAndFormatTests: XCTestCase {
    // MARK: M8

    func testUnitConversions() {
        XCTAssertEqual(SpeedUnit.metric.speed(fromMetersPerSecond: 10), 36, accuracy: 1e-9)
        XCTAssertEqual(SpeedUnit.imperial.speed(fromMetersPerSecond: 0.44704), 1, accuracy: 1e-9)
        XCTAssertEqual(SpeedUnit.imperial.speed(fromMetersPerSecond: 8.9408), 20, accuracy: 1e-9)
        XCTAssertEqual(SpeedUnit.metric.distance(fromMeters: 2500), 2.5, accuracy: 1e-9)
        XCTAssertEqual(SpeedUnit.imperial.distance(fromMeters: 1609.344), 1, accuracy: 1e-9)
        XCTAssertEqual(SpeedUnit.metric.speedHeading, "KM/H")
        XCTAssertEqual(SpeedUnit.imperial.speedHeading, "MPH")
        XCTAssertEqual(SpeedUnit.imperial.distanceSuffix, "mi")
    }

    // MARK: M6, BESLUT B16: a fixed scale that lights up as the trip gets faster

    func testTheScaleRunsFromZeroToTwoHundredSixtyKmh() {
        let m = Dial(unit: .metric)
        XCTAssertEqual(m.angle(forValue: 0), -120, accuracy: 1e-9)
        XCTAssertEqual(m.angle(forValue: -5), -120, accuracy: 1e-9, "clamped")
        XCTAssertEqual(m.angle(forValue: 10), -103, accuracy: 1e-9, "the first ten is 17 degrees")
        XCTAssertEqual(m.angle(forValue: 100), 40, accuracy: 1e-9, "0-100 takes 160 degrees")
        XCTAssertEqual(m.angle(forValue: 110), 45.5, accuracy: 1e-9, "half of the first twenty")
        XCTAssertEqual(m.angle(forValue: 260), 120, accuracy: 1e-9)
        XCTAssertEqual(m.angle(forValue: 320), 120, accuracy: 1e-9, "past the end the needle stops there")
        XCTAssertEqual(m.angle(forSpeed: 100 / 3.6), 40, accuracy: 1e-9)
        // mph numbers stand where the same speed stands in km/h.
        let i = Dial(unit: .imperial)
        XCTAssertEqual(i.angle(forValue: 60), m.angle(forValue: 60 * 1.609344), accuracy: 1e-9)
        XCTAssertEqual(i.angle(forSpeed: 25), m.angle(forSpeed: 25), accuracy: 1e-12)
    }

    func testTheGapsNarrowAsTheSpeedRises() {
        for unit in [SpeedUnit.metric, .imperial] {
            let labels = Dial(unit: unit, fitting: 1000).labels
            XCTAssertEqual(labels.map { $0.value }, Dial.numbers(unit))
            var last = Double.infinity
            for (a, b) in zip(labels, labels.dropFirst()) {
                XCTAssertLessThan(b.angle - a.angle, last, "\(unit) \(a.value)-\(b.value)")
                last = b.angle - a.angle
            }
        }
        XCTAssertEqual(Dial.numbers(.metric), [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 140, 160, 180, 200, 220, 240, 260])
        XCTAssertEqual(Dial.numbers(.imperial), [0, 10, 20, 30, 40, 50, 60, 80, 100, 120, 140, 160])
    }

    func testNewNumbersLightUpOneAtATime() {
        let metric: [(Double, Int)] = [(0, 100), (25, 100), (100, 100), (101, 120), (130, 140), (250, 260), (320, 260)]
        for (kmh, top) in metric {
            XCTAssertEqual(Dial(unit: .metric, fitting: kmh / 3.6).top, top, "\(kmh) km/h")
        }
        let imperial: [(Double, Int)] = [(0, 60), (60, 60), (61, 80), (150, 160), (200, 160)]
        for (mph, top) in imperial {
            XCTAssertEqual(Dial(unit: .imperial, fitting: mph * 0.44704).top, top, "\(mph) mph")
        }
        XCTAssertEqual(Dial.top(fitting: .nan, unit: .metric), 100)
        XCTAssertEqual(Dial(unit: .metric).labels.map { $0.value }, Array(stride(from: 0, through: 100, by: 10)))
        XCTAssertEqual(Dial(unit: .metric, fitting: 130 / 3.6).labels.suffix(3).map { $0.value }, [100, 120, 140])
        XCTAssertEqual(Dial(unit: .imperial).labels.map { $0.value }, [0, 10, 20, 30, 40, 50, 60])
    }

    func testLitTicksNeverMove() {
        // A faster trip only adds ticks at the end; every tick that was lit keeps its angle.
        let first = Dial(unit: .metric).ticks
        let all = Dial(unit: .metric, fitting: 1000).ticks
        XCTAssertEqual(Array(all.prefix(first.count)), first)
        XCTAssertEqual(first.count, 51)
        XCTAssertEqual(all.count, 83)
        XCTAssertEqual(all.last?.value, 260)
        XCTAssertEqual(first[5].value, 10)
        XCTAssertTrue(first[5].isMajor)
        XCTAssertFalse(first[1].isMajor)
        XCTAssertEqual(all[51].value, 105, "every 5 above 100")
        XCTAssertEqual(Dial(unit: .imperial, fitting: 1000).ticks.count, 51)
    }

    func testTicksNeverCrowd() {
        for unit in [SpeedUnit.metric, .imperial] {
            let ticks = Dial(unit: unit, fitting: 1000).ticks
            for (a, b) in zip(ticks, ticks.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b.angle - a.angle, 2.2, "\(unit) \(a.value)-\(b.value)")
            }
        }
    }

    func testNumbersNeverOverlap() {
        // Each number as a box at radius 112 (FORM.md): 17 pt digits about 10.2 pt wide and 12.5 pt high. Neighbours
        // keep at least 2 pt apart, sideways near the top and up and down on the right.
        for unit in [SpeedUnit.metric, .imperial] {
            let boxes = Dial(unit: unit, fitting: 1000).labels.map { tick -> (x: Double, y: Double, w: Double) in
                let p = Dial.point(radius: 112, angle: tick.angle)
                return (p.x, p.y, Double(String(tick.value).count) * 10.2)
            }
            for (a, b) in zip(boxes, boxes.dropFirst()) {
                let sideways = abs(b.x - a.x) - (a.w + b.w) / 2
                let upDown = abs(b.y - a.y) - 12.5
                XCTAssertGreaterThanOrEqual(max(sideways, upDown), 2, "\(unit) at \(a.x), \(a.y)")
            }
        }
    }

    func testPointOnRadius() {
        let up = Dial.point(radius: 100, angle: 0)
        XCTAssertEqual(up.x, 170, accuracy: 1e-9)
        XCTAssertEqual(up.y, 70, accuracy: 1e-9)
        let right = Dial.point(radius: 100, angle: 90)
        XCTAssertEqual(right.x, 270, accuracy: 1e-9)
        XCTAssertEqual(right.y, 170, accuracy: 1e-9)
        let tail = Dial.point(radius: -20, angle: 0)
        XCTAssertEqual(tail.y, 190, accuracy: 1e-9)
    }

    // MARK: M7

    func testSpeedFormat() {
        XCTAssertEqual(Format.speed(10, unit: .metric), "36")
        XCTAssertEqual(Format.speed(10, unit: .imperial), "22")
        XCTAssertEqual(Format.speed(0, unit: .metric), "0")
        XCTAssertEqual(Format.speed(nil, unit: .metric), "\u{2013}")
    }

    func testDistanceFormat() {
        XCTAssertEqual(Format.distance(12_400, unit: .metric), "12.4")
        XCTAssertEqual(Format.distance(12_449, unit: .metric), "12.4")
        XCTAssertEqual(Format.distance(0, unit: .metric), "0.0")
        XCTAssertEqual(Format.distance(1609.344, unit: .imperial), "1.0")
        XCTAssertEqual(Format.distance(100_000, unit: .metric), "100.0")
    }

    func testAverageFormat() {
        XCTAssertEqual(Format.averageSpeed(5, unit: .metric), "18.0")
        XCTAssertEqual(Format.averageSpeed(nil, unit: .metric), "\u{2013}")
    }

    func testDurationFormat() {
        XCTAssertEqual(Format.duration(0), "0:00")
        XCTAssertEqual(Format.duration(59.9), "0:59")
        XCTAssertEqual(Format.duration(2052), "34:12")
        XCTAssertEqual(Format.duration(3600), "1:00:00")
        XCTAssertEqual(Format.duration(3723), "1:02:03")
    }
}
