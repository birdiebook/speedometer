import Foundation

/// The trip: smoothing, auto-pause, distance, time and max from GPS samples (BESLUT B6).
public struct TripEngine {
    // METOD M2: smoothing time constant, seconds.
    public static let smoothingTau: Double = 1.0
    // METOD M3: pause below this smoothed speed (m/s) for `pauseAfter` seconds; resume at `resumeSpeed`.
    public static let pauseSpeed: Double = 0.8
    public static let pauseAfter: TimeInterval = 3
    public static let resumeSpeed: Double = 1.4
    // METOD M3: no valid sample for this long means no GPS.
    public static let noFixTimeout: TimeInterval = 5
    // METOD M4: longest interval counted for distance and time.
    public static let maxStep: TimeInterval = 3

    public private(set) var state: TripState = .findingGPS
    public private(set) var trip: Trip

    private var smoothed: Double?
    private var lastValidTime: TimeInterval?
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
        guard sample.isValid else { return } // METOD M1

        // METOD M4: delta capped at 3 s; the first sample after a gap has no delta.
        var dt: Double = 0
        if let last = lastValidTime {
            dt = min(max(sample.time - last, 0), TripEngine.maxStep)
        }
        lastValidTime = sample.time

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

    /// METOD M3: call about once a second. No valid sample for 5 s means no GPS.
    public mutating func tick(now: TimeInterval) {
        guard state != .findingGPS, let last = lastValidTime else { return }
        if now - last >= TripEngine.noFixTimeout {
            state = .findingGPS
            smoothed = nil
            lastValidTime = nil
            belowSince = nil
        }
    }
}
