import Foundation

/// One point of the trail (METOD M9).
public struct TrailPoint: Equatable {
    /// Degrees.
    public var latitude: Double
    public var longitude: Double
    /// Smoothed speed in m/s (METOD M2).
    public var speed: Double
    /// The trip's distance (m) and moving time (s) when the point was taken (METOD M4).
    public var distance: Double
    public var time: Double
    /// Not connected to the point before: a GPS gap or the app in the background (METOD M9).
    public var gapBefore: Bool

    public init(latitude: Double, longitude: Double, speed: Double, distance: Double, time: Double,
                gapBefore: Bool = false) {
        self.latitude = latitude
        self.longitude = longitude
        self.speed = speed
        self.distance = distance
        self.time = time
        self.gapBefore = gapBefore
    }
}

/// Saved as a short array, `[lat, lon, speed, distance, time, gap]`, so a long trail stays a small file.
extension TrailPoint: Codable {
    public init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        latitude = try c.decode(Double.self)
        longitude = try c.decode(Double.self)
        speed = try c.decode(Double.self)
        distance = try c.decode(Double.self)
        time = try c.decode(Double.self)
        gapBefore = try c.decode(Int.self) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.unkeyedContainer()
        try c.encode(latitude)
        try c.encode(longitude)
        try c.encode(speed)
        try c.encode(distance)
        try c.encode(time)
        try c.encode(gapBefore ? 1 : 0)
    }
}

/// The trail of the current trip (BESLUT B16, METOD M9). Kept only on the phone (BESLUT B3).
public struct Trail: Codable, Equatable {
    // METOD M9: a new point at least this far (m) from the last one.
    public static let minSpacing: Double = 10
    // METOD M9: further than this many spacings from the last point is a gap.
    public static let gapFactor: Double = 5
    // METOD M9: above this many points every other point goes and the spacing doubles.
    public static let maxPoints = 20_000
    // METOD M9: the earth's radius in metres for the local flat projection.
    public static let earthRadius: Double = 6_371_000

    public private(set) var points: [TrailPoint]
    /// The current spacing in metres: `minSpacing`, doubled each time the trail is thinned (METOD M9).
    public private(set) var spacing: Double

    public init() {
        points = []
        spacing = Trail.minSpacing
    }

    public var isEmpty: Bool { points.isEmpty }

    /// METOD M9: keeps the point if it is at least `spacing` from the last one; marks a gap when it is far away.
    public mutating func add(latitude: Double, longitude: Double, speed: Double, distance: Double, time: Double) {
        var point = TrailPoint(latitude: latitude, longitude: longitude, speed: speed, distance: distance, time: time)
        if let last = points.last {
            let d = Trail.meters(fromLatitude: last.latitude, longitude: last.longitude,
                                 toLatitude: latitude, longitude: longitude)
            guard d >= spacing else { return }
            point.gapBefore = d > spacing * Trail.gapFactor
        }
        points.append(point)
        if points.count > Trail.maxPoints { thin() }
    }

    /// METOD M9: drops every other point, keeping the first and the last, and doubles the spacing. A gap next to a
    /// dropped point moves to the next kept point, so it is still drawn.
    private mutating func thin() {
        var kept: [TrailPoint] = []
        kept.reserveCapacity(points.count / 2 + 1)
        var pendingGap = false
        let lastIndex = points.count - 1
        for (i, p) in points.enumerated() {
            if i % 2 == 0 || i == lastIndex {
                var q = p
                q.gapBefore = (p.gapBefore || pendingGap) && !kept.isEmpty
                kept.append(q)
                pendingGap = false
            } else if p.gapBefore {
                pendingGap = true
            }
        }
        points = kept
        spacing *= 2
    }

    /// METOD M9: distance in metres in a local flat (equirectangular) projection; plenty for a bike ride.
    public static func meters(fromLatitude lat1: Double, longitude lon1: Double,
                              toLatitude lat2: Double, longitude lon2: Double) -> Double {
        let r = Double.pi / 180
        let midLatitude = (lat1 + lat2) / 2 * r
        let dx = (lon2 - lon1) * r * cos(midLatitude) * earthRadius
        let dy = (lat2 - lat1) * r * earthRadius
        return (dx * dx + dy * dy).squareRoot()
    }
}
