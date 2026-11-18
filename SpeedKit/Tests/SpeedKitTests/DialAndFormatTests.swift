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
        XCTAssertEqual(SpeedUnit.metric.baseScaleMax, 60)
        XCTAssertEqual(SpeedUnit.imperial.baseScaleMax, 40)
        XCTAssertEqual(SpeedUnit.metric.speedHeading, "KM/H")
        XCTAssertEqual(SpeedUnit.imperial.speedHeading, "MPH")
        XCTAssertEqual(SpeedUnit.imperial.distanceSuffix, "mi")
    }

    // MARK: M6

    func testDialAnglesMetric() {
        let d = Dial(unit: .metric)
        XCTAssertEqual(d.angle(forValue: 0), -120, accuracy: 1e-9)
        XCTAssertEqual(d.angle(forValue: 30), 0, accuracy: 1e-9)
        XCTAssertEqual(d.angle(forValue: 60), 120, accuracy: 1e-9)
        XCTAssertEqual(d.angle(forValue: 80), 120, accuracy: 1e-9, "clamped")
        XCTAssertEqual(d.angle(forValue: -5), -120, accuracy: 1e-9, "clamped")
        XCTAssertEqual(d.angle(forSpeed: 30 / 3.6), 0, accuracy: 1e-9)
    }

    func testDialAnglesImperial() {
        let d = Dial(unit: .imperial)
        XCTAssertEqual(d.angle(forValue: 20), 0, accuracy: 1e-9)
        XCTAssertEqual(d.angle(forValue: 40), 120, accuracy: 1e-9)
        XCTAssertEqual(d.angle(forSpeed: 20 * 0.44704), 0, accuracy: 1e-9)
    }

    func testTicksAndLabels() {
        let m = Dial(unit: .metric)
        XCTAssertEqual(m.ticks.count, 31)
        XCTAssertEqual(m.ticks.filter { $0.isMajor }.count, 7)
        XCTAssertEqual(m.labels.map { $0.value }, [0, 10, 20, 30, 40, 50, 60])
        XCTAssertEqual(m.ticks[5].value, 10)
        XCTAssertEqual(m.ticks[5].angle, -80, accuracy: 1e-9)
        XCTAssertTrue(m.ticks[5].isMajor)
        XCTAssertFalse(m.ticks[1].isMajor)
        let i = Dial(unit: .imperial)
        XCTAssertEqual(i.ticks.count, 21)
        XCTAssertEqual(i.labels.map { $0.value }, [0, 10, 20, 30, 40])
        XCTAssertEqual(i.labels[2].angle, 0, accuracy: 1e-9)
    }

    // MARK: M6, BESLUT B16: the scale grows with the trip

    func testTheScaleStartsAtSixtyAndGrowsInStepsWithoutACeiling() {
        let metric: [(Double, Double)] = [
            (0, 60), (60, 60), (60.01, 120), (120, 120), (121, 180), (180, 180), (181, 240),
            (241, 360), (361, 480), (481, 720), (900, 960), (1000, 1440), (5000, 5760),
        ]
        for (value, end) in metric {
            XCTAssertEqual(60 * Double(Dial.factor(fitting: value, base: 60)), end, "\(value) km/h")
        }
        let imperial: [(Double, Double)] = [(0, 40), (40, 40), (41, 80), (75, 80), (81, 120), (200, 240), (241, 320)]
        for (value, end) in imperial {
            XCTAssertEqual(40 * Double(Dial.factor(fitting: value, base: 40)), end, "\(value) mph")
        }
        XCTAssertEqual(Dial.factor(fitting: .infinity, base: 60), 1)
        XCTAssertEqual(Dial.factor(fitting: .nan, base: 60), 1)
    }

    func testTheScaleFitsASpeedInMetresPerSecond() {
        XCTAssertEqual(Dial(unit: .metric).scaleMax, 60)
        XCTAssertEqual(Dial(unit: .metric, fitting: 45 / 3.6).scaleMax, 60, "a bike")
        XCTAssertEqual(Dial(unit: .metric, fitting: 130 / 3.6).scaleMax, 180, "a car on the motorway")
        XCTAssertEqual(Dial(unit: .metric, fitting: 250 / 3.6).scaleMax, 360, "a sports car")
        XCTAssertEqual(Dial(unit: .metric, fitting: 320 / 3.6).scaleMax, 360, "a high-speed train")
        XCTAssertEqual(Dial(unit: .imperial, fitting: 70 * 0.44704).scaleMax, 80)
    }

    func testAGrownScaleKeepsItsTicksAndChangesOnlyTheLabels() {
        let first = Dial(unit: .metric)
        let car = Dial(unit: .metric, fitting: 130 / 3.6)
        XCTAssertEqual(car.ticks.count, first.ticks.count)
        XCTAssertEqual(car.ticks.map { $0.angle }, first.ticks.map { $0.angle })
        XCTAssertEqual(car.ticks.map { $0.isMajor }, first.ticks.map { $0.isMajor })
        XCTAssertEqual(car.labels.map { $0.value }, [0, 30, 60, 90, 120, 150, 180])
        XCTAssertEqual(car.angle(forValue: 90), 0, accuracy: 1e-9)
        XCTAssertEqual(car.angle(forSpeed: 200 / 3.6), 120, accuracy: 1e-9, "clamped at the end")
        let train = Dial(unit: .metric, fitting: 320 / 3.6)
        XCTAssertEqual(train.labels.map { $0.value }, [0, 60, 120, 180, 240, 300, 360])
        XCTAssertEqual(train.ticks[1].value, 12)
        let mph = Dial(unit: .imperial, fitting: 190 * 0.44704)
        XCTAssertEqual(mph.labels.map { $0.value }, [0, 60, 120, 180, 240])
        XCTAssertEqual(mph.ticks.count, Dial(unit: .imperial).ticks.count)
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
