import Foundation

/// The numbers of one trip, and the only thing that is saved (BESLUT B3, B10).
public struct Trip: Codable, Equatable {
    /// Metres.
    public var distance: Double
    /// Seconds while riding (METOD M4).
    public var movingTime: Double
    /// Highest smoothed speed in m/s (METOD M5).
    public var maxSpeed: Double

    public init(distance: Double = 0, movingTime: Double = 0, maxSpeed: Double = 0) {
        self.distance = distance
        self.movingTime = movingTime
        self.maxSpeed = maxSpeed
    }

    /// METOD M4: distance / time in m/s; nil before any moving time.
    public var averageSpeed: Double? {
        movingTime > 0 ? distance / movingTime : nil
    }

    /// BESLUT B15: nothing ridden yet (a new or reset trip). The screen shows no PAUSED then.
    public var isEmpty: Bool {
        distance == 0 && movingTime == 0 && maxSpeed == 0
    }
}

/// BESLUT B5: the three modes of the screen.
public enum TripState: Equatable {
    case findingGPS
    case riding
    case paused
}
