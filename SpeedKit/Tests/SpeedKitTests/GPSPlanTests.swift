import XCTest
@testable import SpeedKit

/// When the GPS runs (METOD M11, BESLUT B17), with made-up times and positions near the equator.
final class GPSPlanTests: XCTestCase {
    private let deg = 180 / (Double.pi * Trail.earthRadius)

    /// A coarse position `north` metres north of (0, 0), as in the saving mode: no speed.
    private func coarse(_ t: Double, north: Double) -> GPSSample {
        GPSSample(time: t, speed: -1, speedAccuracy: -1, horizontalAccuracy: 65, latitude: north * deg, longitude: 0)
    }

    private func moving(_ t: Double) -> GPSSample {
        GPSSample(time: t, speed: 6, speedAccuracy: 0.5, horizontalAccuracy: 5, latitude: 0, longitude: 0)
    }

    func testTheForegroundIsAlwaysFull() {
        var p = GPSPlan()
        XCTAssertEqual(p.mode, .off)
        p.foreground(now: 0)
        XCTAssertEqual(p.mode, .full)
        p.tick(now: 10_000)
        XCTAssertEqual(p.mode, .full)
    }

    func testTheGPSGoesOnInTheBackgroundEvenBeforeTheRide() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.background(now: 100)
        XCTAssertEqual(p.mode, .full)
        p.tick(now: 100 + GPSPlan.savingAfter - 1)
        XCTAssertEqual(p.mode, .full)
        p.tick(now: 100 + GPSPlan.savingAfter)
        XCTAssertEqual(p.mode, .saving)
    }

    func testRidingKeepsItFull() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.background(now: 0)
        for t in stride(from: 0.0, through: 1200, by: 1) { p.sample(moving(t), riding: true, now: t) }
        XCTAssertEqual(p.mode, .full)
        // A stop: two minutes after the last riding sample it saves.
        p.tick(now: 1200 + GPSPlan.savingAfter)
        XCTAssertEqual(p.mode, .saving)
    }

    func testMovingInTheSavingModeWakesTheFullGPS() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.background(now: 0)
        p.tick(now: 200)
        XCTAssertEqual(p.mode, .saving)
        p.sample(coarse(201, north: 0), riding: false, now: 201)    // the anchor
        p.sample(coarse(260, north: 60), riding: false, now: 260)   // wifi jitter
        XCTAssertEqual(p.mode, .saving)
        p.sample(coarse(300, north: 150), riding: false, now: 300)  // moving
        XCTAssertEqual(p.mode, .full)
        // A false alarm: two minutes later it saves again, with a new anchor.
        p.tick(now: 300 + GPSPlan.savingAfter)
        XCTAssertEqual(p.mode, .saving)
        p.sample(coarse(500, north: 150), riding: false, now: 500)
        p.sample(coarse(510, north: 200), riding: false, now: 510)
        XCTAssertEqual(p.mode, .saving)
    }

    func testRidingInTheSavingModeWakesTheFullGPS() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.background(now: 0)
        p.tick(now: 200)
        p.sample(moving(201), riding: true, now: 201)
        XCTAssertEqual(p.mode, .full)
    }

    func testALongStopTurnsTheGPSOffUntilTheAppOpens() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.sample(moving(0), riding: true, now: 0)
        p.background(now: 10)
        p.tick(now: 10 + GPSPlan.offAfter - 1)
        XCTAssertEqual(p.mode, .saving)
        p.tick(now: 10 + GPSPlan.offAfter)
        XCTAssertEqual(p.mode, .off)
        p.sample(moving(5000), riding: true, now: 5000) // a late sample does not restart it
        XCTAssertEqual(p.mode, .off)
        p.foreground(now: 6000)
        XCTAssertEqual(p.mode, .full)
    }

    func testTheBackgroundTimeRestartsEachTime() {
        var p = GPSPlan()
        p.foreground(now: 0)
        p.background(now: 0)
        p.tick(now: 200)
        XCTAssertEqual(p.mode, .saving)
        p.foreground(now: 300)
        p.background(now: 400)
        p.tick(now: 400 + GPSPlan.savingAfter - 1)
        XCTAssertEqual(p.mode, .full)
    }
}
