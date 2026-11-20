import Foundation
import SpeedKit

/// A made-up ride for previews and debug screenshots (BESLUT B16): a route through an invented town at (0, 0), no real
/// place, fed through the real engine at 1 Hz so that the trail and the numbers agree.
enum DemoTrail {
    static let engine: TripEngine = {
        // The route of the sketch, in sketch units with y down: streets, a lake shore and a park path.
        var corners: [(x: Double, y: Double)] = [(60, 650), (64, 600), (150, 596), (154, 560), (250, 552), (258, 470),
                                                 (262, 380)]
        for k in 1...22 {
            let a = (60 - 155 * Double(k) / 22) * Double.pi / 180
            corners.append((x: 215 + 92 * cos(a), y: 300 + 92 * sin(a)))
        }
        let rest: [(x: Double, y: Double)] = [(150, 196), (96, 200), (88, 262), (120, 300), (104, 330), (130, 352),
                                              (112, 382), (140, 410), (128, 440), (100, 446), (98, 520), (44, 524),
                                              (44, 644), (52, 656)]
        corners.append(contentsOf: rest)
        // 9 m per unit, x east and y north.
        let path = corners.map { (x: $0.x * 9, y: -$0.y * 9) }

        var cumulative: [Double] = [0]
        for i in 1..<path.count {
            cumulative.append(cumulative[i - 1] + hypot(path[i].x - path[i - 1].x, path[i].y - path[i - 1].y))
        }
        let total = cumulative[cumulative.count - 1]

        // Sharp corners (more than 30 degrees) slow the ride down.
        var sharp: [Double] = []
        for i in 1..<(path.count - 1) {
            let h1 = atan2(path[i].y - path[i - 1].y, path[i].x - path[i - 1].x)
            let h2 = atan2(path[i + 1].y - path[i].y, path[i + 1].x - path[i].x)
            var turn = abs(h2 - h1)
            if turn > Double.pi { turn = 2 * Double.pi - turn }
            if turn > Double.pi / 6 { sharp.append(cumulative[i]) }
        }

        func position(at s: Double) -> (x: Double, y: Double) {
            var i = 1
            while i < path.count - 1 && cumulative[i] < s { i += 1 }
            let length = cumulative[i] - cumulative[i - 1]
            let u = length > 0 ? min(max((s - cumulative[i - 1]) / length, 0), 1) : 0
            return (x: path[i - 1].x + (path[i].x - path[i - 1].x) * u,
                    y: path[i - 1].y + (path[i].y - path[i - 1].y) * u)
        }

        func bump(_ f: Double, _ from: Double, _ to: Double) -> Double {
            (f > from && f < to) ? sin((f - from) / (to - from) * Double.pi) : 0
        }

        // m/s: a long fast street, a quick descent past the lake, a slow park path; slower at corners, start and end.
        func speed(at s: Double) -> Double {
            let f = s / total
            var cruise = 6.5 + 3 * bump(f, 0.22, 0.36) + 3.5 * bump(f, 0.50, 0.58)
            if f > 0.62 && f < 0.80 { cruise -= 2.5 }
            let corner = sharp.map { abs($0 - s) }.min() ?? 1000
            let v = min(cruise, 2 + 0.12 * corner, 2 + 0.3 * s, 1 + 0.2 * (total - s))
            return max(v, 1.6)
        }

        let degreesPerMeter = 180 / (Double.pi * Trail.earthRadius)
        var e = TripEngine()
        var s = 0.0
        var t = 0.0
        while s < total {
            let v = speed(at: s)
            let p = position(at: s)
            e.ingest(GPSSample(time: t, speed: v, speedAccuracy: 0.5, horizontalAccuracy: 5,
                               latitude: p.y * degreesPerMeter, longitude: p.x * degreesPerMeter))
            s += v
            t += 1
        }
        return e
    }()

    /// A point a little under half way, on the lake shore, for the finger shots.
    static var fingerIndex: Int { engine.trail.points.count * 47 / 100 }
}
