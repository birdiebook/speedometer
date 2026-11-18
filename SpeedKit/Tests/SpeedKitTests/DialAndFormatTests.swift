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

    func testSixtyIsStraightUpAndTheScaleHasNoEnd() {
        let m = Dial(unit: .metric)
        XCTAssertEqual(m.angle(forValue: 0), -120, accuracy: 1e-9)
        XCTAssertEqual(m.angle(forValue: 60), 0, accuracy: 1e-9)
        XCTAssertEqual(m.angle(forValue: -5), -120, accuracy: 1e-9, "clamped")
        XCTAssertEqual(m.angle(forSpeed: 60 / 3.6), 0, accuracy: 1e-9)
        XCTAssertLessThan(m.angle(forValue: 100_000), 120, "no ceiling: the end is never reached")
        XCTAssertGreaterThan(m.angle(forValue: 100_000), 119.8)
        let i = Dial(unit: .imperial)
        XCTAssertEqual(i.angle(forValue: 40), 0, accuracy: 1e-9)
        XCTAssertEqual(i.angle(forSpeed: 40 * 0.44704), 0, accuracy: 1e-9)
    }

    func testEachTenIsNarrowerThanTheOneBefore() {
        for unit in [SpeedUnit.metric, .imperial] {
            let d = Dial(unit: unit)
            var last = Double.infinity
            for v in stride(from: 0, to: 200, by: 10) {
                let width = d.angle(forValue: Double(v + 10)) - d.angle(forValue: Double(v))
                XCTAssertLessThan(width, last, "\(unit) \(v)")
                last = width
            }
        }
        XCTAssertEqual(Dial(unit: .metric).angle(forValue: 10) + 120, 25.2, accuracy: 0.05, "0-10 km/h")
    }

    func testNewNumbersLightUpAsTheTripGetsFaster() {
        let metric: [(Double, Int)] = [(0, 100), (25, 100), (100, 100), (101, 200), (130, 200), (250, 500), (320, 500), (900, 500)]
        for (kmh, top) in metric {
            XCTAssertEqual(Dial(unit: .metric, fitting: kmh / 3.6).top, top, "\(kmh) km/h")
        }
        let imperial: [(Double, Int)] = [(0, 60), (60, 60), (61, 100), (150, 200), (300, 500)]
        for (mph, top) in imperial {
            XCTAssertEqual(Dial(unit: .imperial, fitting: mph * 0.44704).top, top, "\(mph) mph")
        }
        XCTAssertEqual(Dial.top(fitting: .nan, unit: .metric), 100)
        XCTAssertEqual(Dial(unit: .metric).labels.map { $0.value }, [0, 10, 20, 30, 40, 50, 60, 80, 100])
        XCTAssertEqual(Dial(unit: .metric, fitting: 130 / 3.6).labels.last?.value, 200)
        XCTAssertEqual(Dial(unit: .metric, fitting: 320 / 3.6).labels.last?.value, 500)
        XCTAssertEqual(Dial(unit: .imperial).labels.map { $0.value }, [0, 10, 20, 30, 40, 50, 60])
    }

    func testLitTicksNeverMove() {
        // A faster trip only adds ticks at the end; every tick that was lit keeps its angle.
        let first = Dial(unit: .metric).ticks
        let train = Dial(unit: .metric, fitting: 320 / 3.6).ticks
        XCTAssertEqual(Array(train.prefix(first.count)), first)
        XCTAssertEqual(first.count, 39)
        XCTAssertEqual(train.count, 55)
        XCTAssertEqual(train.last?.value, 500)
        XCTAssertEqual(first[5].value, 10)
        XCTAssertTrue(first[5].isMajor)
        XCTAssertFalse(first[1].isMajor)
        XCTAssertEqual(first[31].value, 65, "every 5 from 60")
    }

    func testTicksNeverCrowd() {
        for unit in [SpeedUnit.metric, .imperial] {
            let ticks = Dial(unit: unit, fitting: 1000).ticks
            XCTAssertEqual(ticks.last?.value, 500)
            for (a, b) in zip(ticks, ticks.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b.angle - a.angle, 1.9, "\(unit) \(a.value)-\(b.value)")
            }
        }
        XCTAssertEqual(Dial(unit: .imperial, fitting: 1000).ticks.count, 47)
    }

    func testNumbersNeverCrowd() {
        // At least 13 degrees between neighbouring numbers, about 25 pt at the numbers' radius (FORM.md).
        for unit in [SpeedUnit.metric, .imperial] {
            let labels = Dial(unit: unit, fitting: 1000).labels
            XCTAssertEqual(labels.map { $0.value }, Dial.numbers(unit))
            for (a, b) in zip(labels, labels.dropFirst()) {
                XCTAssertGreaterThanOrEqual(b.angle - a.angle, 13, "\(unit) \(a.value)-\(b.value)")
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
