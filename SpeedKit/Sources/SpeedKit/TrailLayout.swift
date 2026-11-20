import Foundation

/// A point on the screen, in points, y down.
public struct TrailXY: Equatable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// Where the trail goes on the screen and in which colour step (BESLUT B16, METOD M10).
/// Segment `k` runs from point `k - 1` to point `k`.
public struct TrailLayout {
    // METOD M10: the trail counts as at least this many metres wide and high.
    public static let minSpan: Double = 300
    // METOD M10: number of colour steps.
    public static let levels = 10

    /// Consecutive segments in the same colour step, as a range of point indices (at least two points).
    public struct Run: Equatable {
        public var level: Int
        public var range: ClosedRange<Int>
        public init(level: Int, range: ClosedRange<Int>) { self.level = level; self.range = range }
    }

    /// One screen position per trail point.
    public let points: [TrailXY]
    /// The colour step of each segment; index 0 is unused (no segment ends at the first point).
    public let segmentLevels: [Int]
    /// Whether segment `k` is a gap (METOD M9).
    public let segmentGaps: [Bool]
    /// The point with the highest speed, for the max marker.
    public let maxIndex: Int?
    /// The area the trail was fitted into, in points.
    public let width: Double
    public let height: Double

    /// Fits `trail` into a `width` x `height` area, `inset` points in from every edge, north up (METOD M10).
    /// `topSpeed` is the trip's max (METOD M5); the colour steps run from 0 to it.
    public init(trail: Trail, topSpeed: Double, width: Double, height: Double, inset: Double = 0) {
        let pts = trail.points
        self.width = width
        self.height = height
        guard !pts.isEmpty else {
            points = []
            segmentLevels = []
            segmentGaps = []
            maxIndex = nil
            return
        }

        // METOD M10: the local flat projection of METOD M9 around the middle of the bounding box.
        let lats = pts.map(\.latitude)
        let lons = pts.map(\.longitude)
        let lat0 = (lats.min()! + lats.max()!) / 2
        let lon0 = (lons.min()! + lons.max()!) / 2
        let r = Double.pi / 180
        let kx = r * cos(lat0 * r) * Trail.earthRadius
        let ky = r * Trail.earthRadius
        let spanX = max((lons.max()! - lons.min()!) * kx, TrailLayout.minSpan)
        let spanY = max((lats.max()! - lats.min()!) * ky, TrailLayout.minSpan)
        let w = max(width - 2 * inset, 0)
        let h = max(height - 2 * inset, 0)
        let scale = min(w / spanX, h / spanY)
        points = pts.map { p in
            TrailXY(x: width / 2 + (p.longitude - lon0) * kx * scale,
                    y: height / 2 - (p.latitude - lat0) * ky * scale)
        }

        var levels = [0]
        var gaps = [false]
        for k in 1..<pts.count {
            levels.append(TrailLayout.level(speed: (pts[k - 1].speed + pts[k].speed) / 2, top: topSpeed))
            gaps.append(pts[k].gapBefore)
        }
        segmentLevels = levels
        segmentGaps = gaps

        var best = 0
        for i in pts.indices where pts[i].speed > pts[best].speed { best = i }
        maxIndex = best
    }

    /// METOD M10: the colour step of a speed, 0 to `levels - 1`, on a scale from 0 to `top`.
    public static func level(speed: Double, top: Double) -> Int {
        guard top > 0, speed > 0 else { return 0 }
        return min(levels - 1, Int(speed / top * Double(levels)))
    }

    /// The whole trail as a point range; nil with fewer than two points.
    public var fullRange: ClosedRange<Int>? {
        points.count >= 2 ? 0...(points.count - 1) : nil
    }

    /// The coloured runs among the segments inside `range`; gaps are left out.
    public func runs(in range: ClosedRange<Int>) -> [Run] {
        var out: [Run] = []
        let lower = max(range.lowerBound, 0)
        let upper = min(range.upperBound, points.count - 1)
        guard upper > lower else { return out }
        for k in (lower + 1)...upper where !segmentGaps[k] {
            if let last = out.last, last.level == segmentLevels[k], last.range.upperBound == k - 1 {
                out[out.count - 1].range = last.range.lowerBound...k
            } else {
                out.append(Run(level: segmentLevels[k], range: (k - 1)...k))
            }
        }
        return out
    }

    /// The gap segments inside `range` (METOD M9), by the index of their end point.
    public func gaps(in range: ClosedRange<Int>) -> [Int] {
        let lower = max(range.lowerBound, 0)
        let upper = min(range.upperBound, points.count - 1)
        guard upper > lower else { return [] }
        return ((lower + 1)...upper).filter { segmentGaps[$0] }
    }

    /// FORM.md: a unit vector across the line at point `i`, for the max marker, so that it sits beside the line and
    /// not on it. It points away from the middle of the trail, or toward it when that would put something `reach`
    /// points out past the edge of the area.
    public func markerDirection(at i: Int, reach: Double) -> TrailXY {
        guard points.count >= 2, points.indices.contains(i) else { return TrailXY(x: 1, y: 0) }
        let a = points[max(i - 3, 0)]
        let b = points[min(i + 3, points.count - 1)]
        let length = ((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)).squareRoot()
        guard length > 0 else { return TrailXY(x: 1, y: 0) }
        var n = TrailXY(x: -(b.y - a.y) / length, y: (b.x - a.x) / length)
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let middle = TrailXY(x: (xs.min()! + xs.max()!) / 2, y: (ys.min()! + ys.max()!) / 2)
        let p = points[i]
        if (p.x - middle.x) * n.x + (p.y - middle.y) * n.y < 0 { n = TrailXY(x: -n.x, y: -n.y) }
        let end = TrailXY(x: p.x + n.x * reach, y: p.y + n.y * reach)
        if end.x < 0 || end.x > width || end.y < 0 || end.y > height { n = TrailXY(x: -n.x, y: -n.y) }
        return n
    }

    /// METOD M10: the point closest to a finger on the screen.
    public func nearestIndex(to p: TrailXY) -> Int? {
        guard !points.isEmpty else { return nil }
        var best = 0
        var bestD = Double.infinity
        for (i, q) in points.enumerated() {
            let d = (q.x - p.x) * (q.x - p.x) + (q.y - p.y) * (q.y - p.y)
            if d < bestD { bestD = d; best = i }
        }
        return best
    }
}
