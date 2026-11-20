import XCTest
@testable import SpeedKit

/// The trail and its picture (METOD M9, M10, BESLUT B16), with made-up positions near the equator.
final class TrailTests: XCTestCase {
    /// Degrees per metre along a meridian.
    private let deg = 180 / (Double.pi * Trail.earthRadius)

    /// A trail point `north` metres north and `east` metres east of (0, 0).
    private func add(_ t: inout Trail, north: Double, east: Double = 0, speed: Double = 5, distance: Double = 0) {
        t.add(latitude: north * deg, longitude: east * deg, speed: speed, distance: distance, time: 0)
    }

    private func good(_ t: Double, _ v: Double, north: Double? = nil) -> GPSSample {
        GPSSample(time: t, speed: v, speedAccuracy: 0.5, horizontalAccuracy: 5,
                  latitude: north.map { $0 * deg }, longitude: north == nil ? nil : 0)
    }

    // MARK: M9

    func testMetersInTheFlatProjection() {
        XCTAssertEqual(Trail.meters(fromLatitude: 0, longitude: 0, toLatitude: 1, longitude: 0), 111_195, accuracy: 1)
        XCTAssertEqual(Trail.meters(fromLatitude: 60, longitude: 0, toLatitude: 60, longitude: 1), 55_597, accuracy: 1)
    }

    func testAPointCloserThanTheSpacingIsSkipped() {
        var t = Trail()
        add(&t, north: 0)
        add(&t, north: 6)
        XCTAssertEqual(t.points.count, 1)
        add(&t, north: 12)
        XCTAssertEqual(t.points.count, 2)
        XCTAssertFalse(t.points[1].gapBefore)
    }

    func testAJumpIsAGap() {
        var t = Trail()
        add(&t, north: 0)
        add(&t, north: 12)
        add(&t, north: 49)   // 37 m: not a gap
        add(&t, north: 110)  // 61 m: a gap (more than 5 x 10 m)
        XCTAssertEqual(t.points.map(\.gapBefore), [false, false, false, true])
    }

    func testThinningKeepsTheEndsAndTheGapsAndDoublesTheSpacing() {
        var t = Trail()
        var north = 0.0
        for i in 0...Trail.maxPoints { // one point more than the limit
            north += (i == 3) ? 100 : 12 // point 3 comes after a gap
            add(&t, north: north, speed: Double(i))
        }
        XCTAssertEqual(t.spacing, 2 * Trail.minSpacing)
        XCTAssertEqual(t.points.count, Trail.maxPoints / 2 + 1)
        XCTAssertEqual(t.points.first!.speed, 0)
        XCTAssertEqual(t.points.last!.speed, Double(Trail.maxPoints))
        // Point 3 is dropped; its gap moves to point 4, now index 2.
        XCTAssertEqual(t.points[2].speed, 4)
        XCTAssertTrue(t.points[2].gapBefore)
        XCTAssertEqual(t.points.filter(\.gapBefore).count, 1)
        XCTAssertFalse(t.points[0].gapBefore)
    }

    func testCodableRoundTrip() throws {
        var t = Trail()
        add(&t, north: 0, speed: 3.25, distance: 0)
        add(&t, north: 80, east: 5, speed: 7.5, distance: 81.5)
        let back = try JSONDecoder().decode(Trail.self, from: JSONEncoder().encode(t))
        XCTAssertEqual(back, t)
        XCTAssertTrue(back.points[1].gapBefore)
    }

    // MARK: M9 in the engine

    func testTheEngineRecordsOnlyWhileRidingAndOnlyWithCoordinates() {
        var stopped = TripEngine()
        stopped.ingest(GPSSample(time: 0, speed: -1, speedAccuracy: -1, horizontalAccuracy: 20, latitude: 0, longitude: 0))
        XCTAssertEqual(stopped.state, .paused)
        XCTAssertTrue(stopped.trail.isEmpty)

        var e = TripEngine()
        e.ingest(good(0, 6)) // riding, but no coordinates
        XCTAssertEqual(e.state, .riding)
        XCTAssertTrue(e.trail.isEmpty)
        for t in 1...21 { e.ingest(good(Double(t), 6, north: Double(t - 1) * 6)) } // 0...120 m, 6 m apart
        XCTAssertEqual(e.trail.points.count, 11) // every 12 m
        XCTAssertEqual(e.trail.points.last!.distance, e.trip.distance, accuracy: 1e-9)
        XCTAssertEqual(e.trail.points.last!.time, e.trip.movingTime, accuracy: 1e-9)
        XCTAssertEqual(e.trail.points.last!.speed, e.displayedSpeed!, accuracy: 1e-9)
        // Standing still at the last point: it pauses, and nothing more is added.
        for t in 22...40 { e.ingest(good(Double(t), 0, north: 120)) }
        XCTAssertEqual(e.state, .paused)
        XCTAssertEqual(e.trail.points.count, 11)
    }

    func testResetClearsTheTrailWithTheTrip() {
        var e = TripEngine()
        for t in 0...10 { e.ingest(good(Double(t), 6, north: Double(t) * 6)) }
        XCTAssertEqual(e.trail.points.count, 6)
        e.reset()
        XCTAssertTrue(e.trail.isEmpty)
        XCTAssertEqual(e.trip, Trip())
    }

    func testARestoredEngineKeepsItsTrail() {
        var t = Trail()
        add(&t, north: 0)
        add(&t, north: 20)
        let e = TripEngine(trip: Trip(distance: 20, movingTime: 4, maxSpeed: 5), trail: t)
        XCTAssertEqual(e.trail, t)
        XCTAssertEqual(e.state, .findingGPS)
    }

    // MARK: M10

    func testTheLayoutIsNorthUpAndKeepsTheAspect() {
        var t = Trail()
        add(&t, north: 0, east: 0)       // south-west corner
        add(&t, north: 1000, east: 0)    // north-west
        add(&t, north: 1000, east: 500)  // north-east
        let l = TrailLayout(trail: t, topSpeed: 5, width: 300, height: 600, inset: 0)
        // 500 x 1000 m into 300 x 600 pt: 0.6 pt per metre both ways.
        XCTAssertEqual(l.points[0].x, 0, accuracy: 0.01)
        XCTAssertEqual(l.points[0].y, 600, accuracy: 0.01)
        XCTAssertEqual(l.points[1].x, 0, accuracy: 0.01)
        XCTAssertEqual(l.points[1].y, 0, accuracy: 0.01)
        XCTAssertEqual(l.points[2].x, 300, accuracy: 0.01)
        XCTAssertEqual(l.points[2].y, 0, accuracy: 0.01)
    }

    func testTheInsetAndTheCentring() {
        var t = Trail()
        add(&t, north: 0)
        add(&t, north: 1000)
        // A north-south line in a wide area: centred across, inset top and bottom.
        let l = TrailLayout(trail: t, topSpeed: 5, width: 400, height: 220, inset: 10)
        XCTAssertEqual(l.points[0].x, 200, accuracy: 0.01)
        XCTAssertEqual(l.points[0].y, 210, accuracy: 0.01)
        XCTAssertEqual(l.points[1].y, 10, accuracy: 0.01)
    }

    func testAShortTripIsNotBlownUp() {
        var t = Trail()
        add(&t, north: 0)
        add(&t, north: 30)
        let l = TrailLayout(trail: t, topSpeed: 5, width: 300, height: 300, inset: 0)
        // Counts as 300 m high: 30 m becomes 30 pt, in the middle.
        XCTAssertEqual(l.points[0].y - l.points[1].y, 30, accuracy: 0.01)
        XCTAssertEqual(l.points[0].y, 165, accuracy: 0.01)
    }

    func testColourLevels() {
        XCTAssertEqual(TrailLayout.level(speed: 0, top: 10), 0)
        XCTAssertEqual(TrailLayout.level(speed: -1, top: 10), 0)
        XCTAssertEqual(TrailLayout.level(speed: 0.99, top: 10), 0)
        XCTAssertEqual(TrailLayout.level(speed: 1, top: 10), 1)
        XCTAssertEqual(TrailLayout.level(speed: 5, top: 10), 5)
        XCTAssertEqual(TrailLayout.level(speed: 10, top: 10), 9)
        XCTAssertEqual(TrailLayout.level(speed: 12, top: 10), 9)
        XCTAssertEqual(TrailLayout.level(speed: 5, top: 0), 0)
    }

    func testRunsGroupTheSameLevelAndLeaveOutGaps() {
        var t = Trail()
        add(&t, north: 0, speed: 2)
        add(&t, north: 20, speed: 2)
        add(&t, north: 40, speed: 2)
        add(&t, north: 60, speed: 9)
        add(&t, north: 200, speed: 9) // a gap
        add(&t, north: 220, speed: 9)
        let l = TrailLayout(trail: t, topSpeed: 10, width: 300, height: 600)
        XCTAssertEqual(l.fullRange, 0...5)
        XCTAssertEqual(l.runs(in: 0...5), [
            TrailLayout.Run(level: 2, range: 0...2),
            TrailLayout.Run(level: 5, range: 2...3),
            TrailLayout.Run(level: 9, range: 4...5),
        ])
        XCTAssertEqual(l.gaps(in: 0...5), [4])
        // Split at a finger on point 3: before and after.
        XCTAssertEqual(l.runs(in: 0...3), [
            TrailLayout.Run(level: 2, range: 0...2),
            TrailLayout.Run(level: 5, range: 2...3),
        ])
        XCTAssertEqual(l.gaps(in: 0...3), [])
        XCTAssertEqual(l.runs(in: 3...5), [TrailLayout.Run(level: 9, range: 4...5)])
        XCTAssertEqual(l.gaps(in: 3...5), [4])
        XCTAssertEqual(l.runs(in: 5...5), [])
    }

    func testNearestPointAndMax() {
        var t = Trail()
        add(&t, north: 0, speed: 3)
        add(&t, north: 500, speed: 8)
        add(&t, north: 1000, speed: 6)
        let l = TrailLayout(trail: t, topSpeed: 8, width: 100, height: 1000)
        XCTAssertEqual(l.maxIndex, 1)
        XCTAssertEqual(l.nearestIndex(to: TrailXY(x: 90, y: 480)), 1)
        XCTAssertEqual(l.nearestIndex(to: TrailXY(x: 0, y: 0)), 2)
        XCTAssertEqual(l.nearestIndex(to: TrailXY(x: 50, y: 990)), 0)
    }

    func testTheMaxMarkerGoesAcrossTheLineAndAwayFromTheMiddle() {
        // A box: up the west side, east along the top, down the east side.
        var t = Trail()
        for n in stride(from: 0.0, through: 1000, by: 50) { add(&t, north: n, east: 0) }
        for e in stride(from: 50.0, through: 1000, by: 50) { add(&t, north: 1000, east: e) }
        for n in stride(from: 950.0, through: 0, by: -50) { add(&t, north: n, east: 1000) }
        let top = 30 // on the top edge, going east
        let west = 5 // on the west side, going north
        // Room around the box: the marker goes outward.
        let roomy = TrailLayout(trail: t, topSpeed: 5, width: 400, height: 400, inset: 60)
        let up = roomy.markerDirection(at: top, reach: 46)
        XCTAssertEqual(up.x, 0, accuracy: 1e-6)
        XCTAssertEqual(up.y, -1, accuracy: 1e-6)
        let left = roomy.markerDirection(at: west, reach: 46)
        XCTAssertEqual(left.x, -1, accuracy: 1e-6)
        XCTAssertEqual(left.y, 0, accuracy: 1e-6)
        // Tight against the edge: it turns inward instead.
        let tight = TrailLayout(trail: t, topSpeed: 5, width: 400, height: 400, inset: 12)
        let down = tight.markerDirection(at: top, reach: 46)
        XCTAssertEqual(down.y, 1, accuracy: 1e-6)
    }

    func testAnEmptyTrailHasNoLayout() {
        let l = TrailLayout(trail: Trail(), topSpeed: 5, width: 300, height: 300)
        XCTAssertTrue(l.points.isEmpty)
        XCTAssertNil(l.fullRange)
        XCTAssertNil(l.maxIndex)
        XCTAssertNil(l.nearestIndex(to: TrailXY(x: 0, y: 0)))
        XCTAssertEqual(l.runs(in: 0...3), [])
    }
}
