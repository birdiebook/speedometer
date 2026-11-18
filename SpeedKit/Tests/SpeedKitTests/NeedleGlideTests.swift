import XCTest
@testable import SpeedKit

/// METOD M2: the needle glides to each new speed instead of jumping. Made-up GPS samples only.
final class NeedleGlideTests: XCTestCase {
    /// The needle as the screen draws it: SwiftUI runs each change's glide side by side and adds them up (a custom
    /// animation that does not merge). `changes` are (time, new value), starting from `start`.
    private func needle(_ changes: [(TimeInterval, Double)], from start: Double = 0, at t: TimeInterval) -> Double {
        var value = start
        var previous = start
        for (time, target) in changes {
            value += (target - previous) * NeedleGlide.progress(t - time)
            previous = target
        }
        return value
    }

    private func rate(_ changes: [(TimeInterval, Double)], at t: TimeInterval) -> Double {
        (needle(changes, at: t + 0.01) - needle(changes, at: t)) / 0.01
    }

    func testAGlideGoesFromTheOldValueToTheNewInOnePointFourSeconds() {
        XCTAssertEqual(NeedleGlide.duration, 1.4, accuracy: 1e-9)
        XCTAssertEqual(NeedleGlide.progress(-1), 0)
        XCTAssertEqual(NeedleGlide.progress(0), 0)
        XCTAssertEqual(NeedleGlide.progress(0.2), 0.05, accuracy: 1e-9)
        XCTAssertEqual(NeedleGlide.progress(0.4), 0.2, accuracy: 1e-9)
        XCTAssertEqual(NeedleGlide.progress(0.7), 0.5, accuracy: 1e-9, "half way at the middle")
        XCTAssertEqual(NeedleGlide.progress(1.0), 0.8, accuracy: 1e-9)
        XCTAssertEqual(NeedleGlide.progress(1.2), 0.95, accuracy: 1e-9)
        XCTAssertEqual(NeedleGlide.progress(1.4), 1)
        XCTAssertEqual(NeedleGlide.progress(9), 1)
    }

    func testTheGlideNeverGoesPastTheNewValueOrBack() {
        var last = 0.0
        for i in 0...1500 {
            let p = NeedleGlide.progress(Double(i) / 1000)
            XCTAssertGreaterThanOrEqual(p, last)
            XCTAssertLessThanOrEqual(p, 1)
            last = p
        }
    }

    func testNoKinks() {
        // The rate is the same just before and just after each corner, and 0 at both ends.
        let h = 1e-7
        func left(_ t: Double) -> Double { (NeedleGlide.progress(t) - NeedleGlide.progress(t - h)) / h }
        func right(_ t: Double) -> Double { (NeedleGlide.progress(t + h) - NeedleGlide.progress(t)) / h }
        XCTAssertEqual(right(0), 0, accuracy: 1e-4)
        XCTAssertEqual(left(0.4), right(0.4), accuracy: 1e-4)
        XCTAssertEqual(right(0.4), 1, accuracy: 1e-4, "full rate is one change per interval")
        XCTAssertEqual(left(1.0), right(1.0), accuracy: 1e-4)
        XCTAssertEqual(left(1.4), 0, accuracy: 1e-4)
    }

    func testEvenStepsEverySecondTurnTheNeedleAtAnEvenPace() {
        // A steady 0.8 m/s² seen at 1 Hz: the needle moves 0.8 m/s per second at every moment, not in hops.
        let changes = (0..<20).map { (Double($0), 0.8 * Double($0 + 1)) }
        for i in 0..<200 {
            XCTAssertEqual(rate(changes, at: 0.5 + Double(i) * 0.09), 0.8, accuracy: 1e-6)
        }
    }

    func testANewValueDuringAGlideCarriesOnFromWhereTheNeedleIs() {
        let first = [(0.0, 10.0)]
        let both = [(0.0, 10.0), (0.6, 4.0)]
        XCTAssertEqual(needle(both, at: 0.6), needle(first, at: 0.6), accuracy: 1e-12, "no jump")
        XCTAssertEqual(needle(both, at: 0.6 + NeedleGlide.duration), 4, accuracy: 1e-12)
    }

    func testWithTheEngineTheNeedleNeverStandsStillAndNeverPassesTheMax() {
        // A ride at 1 Hz: a steady 0.8 m/s² up to 8 m/s, then on at 8. The needle heads for the smoothed speed while
        // riding and 0 otherwise (DialView); the orange marker stands at the max (METOD M5).
        var engine = TripEngine()
        var changes: [(TimeInterval, Double)] = []
        var maxAt: [(TimeInterval, Double)] = []
        for t in 0...15 {
            let time = Double(t)
            engine.ingest(GPSSample(time: time, speed: min(0.8 * time, 8), speedAccuracy: 0.5, horizontalAccuracy: 5))
            changes.append((time, engine.state == .riding ? engine.displayedSpeed ?? 0 : 0))
            maxAt.append((time, engine.trip.maxSpeed))
        }
        XCTAssertEqual(engine.state, .riding)
        for i in 0..<1600 {
            let t = Double(i) / 100
            let marker = maxAt.last { $0.0 <= t }?.1 ?? 0
            XCTAssertLessThanOrEqual(needle(changes, at: t), marker + 1e-9, "t = \(t)")
            if t >= 3.5 && t <= 10.5 {
                XCTAssertGreaterThan(rate(changes, at: t), 0.7, "still at t = \(t)")
            }
        }
        XCTAssertEqual(needle(changes, at: 20), engine.displayedSpeed!, accuracy: 1e-9, "settles on the speed")
    }
}
