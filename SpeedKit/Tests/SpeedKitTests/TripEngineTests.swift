import XCTest
@testable import SpeedKit

/// Made-up GPS samples only (METOD M1-M5).
final class TripEngineTests: XCTestCase {
    private func good(_ t: Double, _ v: Double) -> GPSSample {
        GPSSample(time: t, speed: v, speedAccuracy: 0.5, horizontalAccuracy: 5)
    }

    /// An engine that rides at `v` m/s with samples at t = 0...n (1 Hz).
    private func riding(at v: Double, samples n: Int = 10) -> TripEngine {
        var e = TripEngine()
        for t in 0...n { e.ingest(good(Double(t), v)) }
        return e
    }

    // MARK: M1

    func testInvalidSamplesAreIgnored() {
        var e = TripEngine()
        e.ingest(GPSSample(time: 0, speed: -1, speedAccuracy: 0.5, horizontalAccuracy: 5))
        e.ingest(GPSSample(time: 1, speed: 5, speedAccuracy: 2.5, horizontalAccuracy: 5))
        e.ingest(GPSSample(time: 2, speed: 5, speedAccuracy: 0.5, horizontalAccuracy: 31))
        e.ingest(GPSSample(time: 3, speed: 5, speedAccuracy: -1, horizontalAccuracy: 5))
        e.ingest(GPSSample(time: 4, speed: 5, speedAccuracy: 0.5, horizontalAccuracy: -1))
        XCTAssertEqual(e.state, .findingGPS)
        XCTAssertNil(e.displayedSpeed)
        XCTAssertEqual(e.trip, Trip())
    }

    func testLimitsAreInclusive() {
        XCTAssertTrue(GPSSample(time: 0, speed: 0, speedAccuracy: 2, horizontalAccuracy: 30).isValid)
        XCTAssertFalse(GPSSample(time: 0, speed: 0, speedAccuracy: 2.01, horizontalAccuracy: 30).isValid)
        XCTAssertFalse(GPSSample(time: 0, speed: 0, speedAccuracy: 2, horizontalAccuracy: 30.01).isValid)
    }

    // MARK: M2

    func testSmoothingFollowsTheExponentialAndConverges() {
        var e = TripEngine()
        e.ingest(good(0, 0))
        e.ingest(good(1, 10))
        XCTAssertEqual(e.displayedSpeed!, 10 * (1 - exp(-1.0)), accuracy: 1e-9)
        for t in 2...15 { e.ingest(good(Double(t), 10)) }
        XCTAssertEqual(e.displayedSpeed!, 10, accuracy: 0.01)
    }

    func testFirstSampleStartsFromTheRawSpeed() {
        var e = TripEngine()
        e.ingest(good(0, 7))
        XCTAssertEqual(e.displayedSpeed!, 7, accuracy: 1e-9)
    }

    // MARK: M3

    func testAutoPauseAfterThreeSecondsBelowThreshold() {
        var e = riding(at: 5) // samples to t = 10, smoothed 5
        XCTAssertEqual(e.state, .riding)
        e.ingest(good(11, 0)) // 1.84
        XCTAssertEqual(e.state, .riding)
        e.ingest(good(12, 0)) // 0.68, below 0.8 from here
        XCTAssertLessThan(e.displayedSpeed!, 0.8)
        e.ingest(good(13, 0))
        e.ingest(good(14, 0))
        XCTAssertEqual(e.state, .riding, "only 2 s below the threshold")
        e.ingest(good(15, 0))
        XCTAssertEqual(e.state, .paused)
    }

    func testShortDipDoesNotPause() {
        var e = riding(at: 5)
        e.ingest(good(11, 0))
        e.ingest(good(12, 0))
        e.ingest(good(13, 5))
        e.ingest(good(14, 5))
        e.ingest(good(15, 5))
        e.ingest(good(16, 5))
        XCTAssertEqual(e.state, .riding)
    }

    func testStaysPausedAtOneMeterPerSecond() {
        var e = TripEngine()
        e.ingest(good(0, 0))
        XCTAssertEqual(e.state, .paused)
        for t in 1...30 { e.ingest(good(Double(t), 1.0)) }
        XCTAssertEqual(e.displayedSpeed!, 1.0, accuracy: 0.01)
        XCTAssertEqual(e.state, .paused)
    }

    func testResumesAtOnePointFour() {
        var e = TripEngine()
        e.ingest(good(0, 0))
        e.ingest(good(1, 2)) // 1.264
        XCTAssertEqual(e.state, .paused)
        e.ingest(good(2, 2)) // 1.729
        XCTAssertEqual(e.state, .riding)
    }

    func testNoValidSampleForFiveSecondsMeansFindingGPS() {
        var e = riding(at: 5) // last valid at t = 10
        e.tick(now: 14.9)
        XCTAssertEqual(e.state, .riding)
        e.ingest(GPSSample(time: 13, speed: 5, speedAccuracy: 9, horizontalAccuracy: 5)) // invalid, no refresh
        e.tick(now: 15)
        XCTAssertEqual(e.state, .findingGPS)
        XCTAssertNil(e.displayedSpeed)
        XCTAssertEqual(e.trip.movingTime, 10, accuracy: 1e-9, "the trip is kept")
    }

    func testRecoversFromFindingGPSWithoutAddingTheGap() {
        var e = riding(at: 5)
        let before = e.trip
        e.tick(now: 20)
        XCTAssertEqual(e.state, .findingGPS)
        e.ingest(good(30, 6))
        XCTAssertEqual(e.state, .riding)
        XCTAssertEqual(e.displayedSpeed!, 6, accuracy: 1e-9)
        XCTAssertEqual(e.trip.distance, before.distance, accuracy: 1e-9)
        XCTAssertEqual(e.trip.movingTime, before.movingTime, accuracy: 1e-9)
    }

    func testTickDoesNothingBeforeTheFirstFix() {
        var e = TripEngine()
        e.tick(now: 100)
        XCTAssertEqual(e.state, .findingGPS)
    }

    // MARK: M4

    func testDistanceIsRawSpeedTimesDeltaWithTheDeltaCapped() {
        var e = TripEngine()
        e.ingest(good(0, 5))
        e.ingest(good(1, 5))
        e.ingest(good(2, 5))
        XCTAssertEqual(e.trip.distance, 10, accuracy: 1e-9)
        XCTAssertEqual(e.trip.movingTime, 2, accuracy: 1e-9)
        e.ingest(good(10, 5)) // 8 s gap counts as 3 s
        XCTAssertEqual(e.trip.distance, 25, accuracy: 1e-9)
        XCTAssertEqual(e.trip.movingTime, 5, accuracy: 1e-9)
        XCTAssertEqual(e.trip.averageSpeed!, 5, accuracy: 1e-9)
    }

    func testNothingCountsWhilePaused() {
        var e = TripEngine()
        e.ingest(good(0, 0))
        for t in 1...10 { e.ingest(good(Double(t), 0.5)) }
        XCTAssertEqual(e.state, .paused)
        XCTAssertEqual(e.trip, Trip())
    }

    func testAverageSpeed() {
        XCTAssertEqual(Trip(distance: 100, movingTime: 20).averageSpeed!, 5, accuracy: 1e-9)
        XCTAssertNil(Trip().averageSpeed)
    }

    // MARK: M5

    func testMaxUsesTheSmoothedSpeedSoASpikeDoesNotStick() {
        var e = riding(at: 5)
        e.ingest(good(11, 30)) // one spike
        let expected = 5 + (1 - exp(-1.0)) * 25
        XCTAssertEqual(e.trip.maxSpeed, expected, accuracy: 1e-9)
        XCTAssertLessThan(e.trip.maxSpeed, 30)
        e.ingest(good(12, 5))
        e.ingest(good(13, 5))
        XCTAssertEqual(e.trip.maxSpeed, expected, accuracy: 1e-9, "max never falls")
    }

    // MARK: reset and saving

    func testResetClearsTheTripAndKeepsTheMode() {
        var e = riding(at: 5)
        XCTAssertGreaterThan(e.trip.distance, 0)
        e.reset()
        XCTAssertEqual(e.trip, Trip())
        XCTAssertEqual(e.state, .riding)
        XCTAssertEqual(e.displayedSpeed!, 5, accuracy: 1e-9)
    }

    func testTripCodableRoundTrip() throws {
        let trip = Trip(distance: 12_345.6, movingTime: 2052, maxSpeed: 9.25)
        let data = try JSONEncoder().encode(trip)
        XCTAssertEqual(try JSONDecoder().decode(Trip.self, from: data), trip)
    }

    func testRestoredTripStartsInFindingGPSWithItsNumbers() {
        let e = TripEngine(trip: Trip(distance: 1000, movingTime: 300, maxSpeed: 8))
        XCTAssertEqual(e.state, .findingGPS)
        XCTAssertNil(e.displayedSpeed)
        XCTAssertEqual(e.trip.distance, 1000)
    }
}
