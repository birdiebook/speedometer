import Foundation

/// One GPS reading, reduced to what the trip needs. No coordinates: no track is ever kept (BESLUT B3).
public struct GPSSample: Equatable {
    /// Seconds on any monotonic-enough clock; only differences are used.
    public var time: TimeInterval
    /// Speed in m/s. A negative value means invalid (METOD M1).
    public var speed: Double
    /// Speed accuracy in m/s. A negative value means invalid.
    public var speedAccuracy: Double
    /// Horizontal accuracy in metres. A negative value means invalid.
    public var horizontalAccuracy: Double

    public init(time: TimeInterval, speed: Double, speedAccuracy: Double, horizontalAccuracy: Double) {
        self.time = time
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.horizontalAccuracy = horizontalAccuracy
    }

    // METOD M1: limits for a usable sample.
    public static let maxSpeedAccuracy: Double = 2      // m/s
    public static let maxHorizontalAccuracy: Double = 30 // m

    /// METOD M1: speed >= 0, 0 <= speedAccuracy <= 2 m/s, 0 <= horizontalAccuracy <= 30 m.
    public var isValid: Bool {
        speed >= 0
            && speedAccuracy >= 0 && speedAccuracy <= GPSSample.maxSpeedAccuracy
            && horizontalAccuracy >= 0 && horizontalAccuracy <= GPSSample.maxHorizontalAccuracy
    }
}
