import Foundation

/// How the GPS runs (BESLUT B17, METOD M11).
public enum GPSMode: Equatable {
    case off
    /// Best accuracy, every sample.
    case full
    /// Coarse and sparse, mostly from cell and wifi: enough to notice that the ride goes on.
    case saving
}

/// BESLUT B17, METOD M11: keeps the whole trip going with the screen off, without a start button. In the foreground
/// the GPS is always full. In the background it stays full while riding, drops to saving after a stop, wakes when
/// the phone moves again and turns off after a long stop. Times are seconds on any clock.
public struct GPSPlan {
    // METOD M11: no riding for this long in the background gives the saving mode.
    public static let savingAfter: TimeInterval = 120
    // METOD M11: no riding for this long in the background turns the GPS off.
    public static let offAfter: TimeInterval = 3600
    // METOD M11: in the saving mode, this far (m) from its first sample wakes the full GPS.
    public static let wakeDistance: Double = 100
    // METOD M11: the saving mode's accuracy and distance filter, in metres (for the app's location manager).
    public static let savingAccuracy: Double = 100
    public static let savingDistanceFilter: Double = 50

    public private(set) var mode: GPSMode = .off

    private var inBackground = false
    private var backgroundSince: TimeInterval?
    private var lastRiding: TimeInterval?
    private var lastWake: TimeInterval?
    /// The first sample of the saving mode.
    private var anchor: (latitude: Double, longitude: Double)?

    public init() {}

    /// The app is open: full GPS.
    public mutating func foreground(now: TimeInterval) {
        inBackground = false
        backgroundSince = nil
        mode = .full
        anchor = nil
    }

    /// The screen goes off or another app comes forward. The GPS goes on, even before the ride has started.
    public mutating func background(now: TimeInterval) {
        guard !inBackground else { return }
        inBackground = true
        backgroundSince = now
        update(now: now)
    }

    /// After the engine has taken `sample`; `riding` is its state afterwards.
    public mutating func sample(_ sample: GPSSample, riding: Bool, now: TimeInterval) {
        if riding { lastRiding = now }
        if mode == .saving {
            if riding {
                wake(now: now)
            } else if let latitude = sample.latitude, let longitude = sample.longitude {
                if let a = anchor {
                    let d = Trail.meters(fromLatitude: a.latitude, longitude: a.longitude,
                                         toLatitude: latitude, longitude: longitude)
                    if d > GPSPlan.wakeDistance { wake(now: now) }
                } else {
                    anchor = (latitude, longitude)
                }
            }
        }
        update(now: now)
    }

    /// About once a second.
    public mutating func tick(now: TimeInterval) {
        update(now: now)
    }

    private mutating func wake(now: TimeInterval) {
        mode = .full
        lastWake = now
        anchor = nil
    }

    /// METOD M11: the time without riding counts from the latest of the last riding, going to the background and the
    /// last wake.
    private mutating func update(now: TimeInterval) {
        guard inBackground, mode != .off else { return }
        let since = [lastRiding, lastWake, backgroundSince].compactMap { $0 }.max() ?? now
        let idle = now - since
        if idle >= GPSPlan.offAfter {
            mode = .off
            anchor = nil
        } else if mode == .full && idle >= GPSPlan.savingAfter {
            mode = .saving
            anchor = nil
        }
    }
}
