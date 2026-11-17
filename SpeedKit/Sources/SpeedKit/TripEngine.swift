import Foundation

/// The trip: smoothing, auto-pause, distance, time and max from GPS samples (BESLUT B6).
public struct TripEngine {
    // METOD M2: smoothing time constant, seconds.
    public static let smoothingTau: Double = 1.0
    // METOD M3: pause below this smoothed speed (m/s) for `pauseAfter` seconds; resume at `resumeSpeed`.
    public static let pauseSpeed: Double = 0.8
    public static let pauseAfter: TimeInterval = 3
    public static let resumeSpeed: Double = 1.4
    // METOD M3: no position for this long means no GPS.
    public static let noFixTimeout: TimeInterval = 15
    // METOD M4: longest interval counted for distance and time.
    public static let maxStep: TimeInterval = 3

    public private(set) var state: TripState = .findingGPS
    public private(set) var trip: Trip

    private var smoothed: Double?
    /// METOD M3: the last sample with a position (for the 5 s no-GPS timeout).
    private var lastFixTime: TimeInterval?
    /// METOD M4: the last sample with a valid speed (for the step and for "speed unknown").
    private var lastSpeedTime: TimeInterval?
    private var belowSince: TimeInterval?

    /// A restored trip keeps its numbers but starts in findingGPS (BESLUT B10).
    public init(trip: Trip = Trip()) {
        self.trip = trip
    }

    /// METOD M2: the smoothed speed in m/s; nil while finding GPS. While paused the app shows 0 instead.
    public var displayedSpeed: Double? {
        state == .findingGPS ? nil : smoothed
    }

    /// BESLUT B6: long-press resets the trip numbers. Smoothing and mode carry on, so the needle does not blink.
    public mutating func reset() {
        trip = Trip()
    }

    public mutating func ingest(_ sample: GPSSample) {
        guard sample.hasFix else { return } // METOD M1
        lastFixTime = sample.time

        // METOD M3: a position without a valid speed. Indoors and when standing still iOS often gives no speed:
        // that is a stop, not a missing GPS. While riding the speed is held for up to 3 s (a short dropout),
        // then the trip pauses with the needle at 0.
        guard sample.isValid else {
            switch state {
            case .findingGPS:
                stop()
            case .riding:
                if let last = lastSpeedTime, sample.time - last >= TripEngine.pauseAfter { stop() }
            case .paused:
                break
            }
            return
        }

        // METOD M4: delta capped at 3 s; the first sample after a gap has no delta.
        var dt: Double = 0
        if let last = lastSpeedTime {
            dt = min(max(sample.time - last, 0), TripEngine.maxStep)
        }
        lastSpeedTime = sample.time

        // METOD M2: exponential smoothing; the first sample after a gap starts from the raw value.
        let v: Double
        if let previous = smoothed, dt > 0 {
            let alpha = 1 - exp(-dt / TripEngine.smoothingTau)
            v = previous + alpha * (sample.speed - previous)
        } else if let previous = smoothed {
            v = previous // same-time duplicate: no change
        } else {
            v = sample.speed
        }
        smoothed = v

        // METOD M3: auto-pause with a gap between the thresholds.
        switch state {
        case .findingGPS:
            state = v >= TripEngine.resumeSpeed ? .riding : .paused
            belowSince = nil
        case .riding:
            if v < TripEngine.pauseSpeed {
                if belowSince == nil { belowSince = sample.time }
                if let since = belowSince, sample.time - since >= TripEngine.pauseAfter {
                    state = .paused
                    belowSince = nil
                }
            } else {
                belowSince = nil
            }
        case .paused:
            if v >= TripEngine.resumeSpeed {
                state = .riding
                belowSince = nil
            }
        }

        // METOD M4 and M5: only while riding. Distance uses the raw speed, max the smoothed one.
        if state == .riding {
            trip.distance += sample.speed * dt
            trip.movingTime += dt
            trip.maxSpeed = max(trip.maxSpeed, v)
        }
    }

    /// METOD M3: paused with the needle at 0; the next valid speed starts a new step (no distance for the gap).
    private mutating func stop() {
        state = .paused
        smoothed = 0
        lastSpeedTime = nil
        belowSince = nil
    }

    /// METOD M3: call about once a second. Riding without a valid speed for 3 s pauses, whether positions
    /// arrive or not (a tunnel); no position for 15 s means no GPS.
    public mutating func tick(now: TimeInterval) {
        guard state != .findingGPS, let last = lastFixTime else { return }
        if state == .riding, let lastSpeed = lastSpeedTime, now - lastSpeed >= TripEngine.pauseAfter {
            stop()
        }
        if now - last >= TripEngine.noFixTimeout {
            state = .findingGPS
            smoothed = nil
            lastFixTime = nil
            lastSpeedTime = nil
            belowSince = nil
        }
    }
}
