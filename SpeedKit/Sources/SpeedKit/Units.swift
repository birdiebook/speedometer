import Foundation

/// BESLUT B7: metric (km/h, km) or imperial (mph, mi). The app maps the phone's region to this; no locale here.
public enum SpeedUnit: Equatable {
    case metric
    case imperial

    // METOD M8: definitions.
    public static let metersPerSecondPerKmh: Double = 1 / 3.6
    public static let metersPerSecondPerMph: Double = 0.44704
    public static let metersPerMile: Double = 1609.344

    /// Metres per second in one displayed speed unit.
    public var metersPerSecondPerUnit: Double {
        switch self {
        case .metric: return SpeedUnit.metersPerSecondPerKmh
        case .imperial: return SpeedUnit.metersPerSecondPerMph
        }
    }

    public var metersPerDistanceUnit: Double {
        switch self {
        case .metric: return 1000
        case .imperial: return SpeedUnit.metersPerMile
        }
    }

    /// Under the big number (FORM.md).
    public var speedHeading: String { self == .metric ? "KM/H" : "MPH" }
    /// After the average (FORM.md).
    public var speedSuffix: String { self == .metric ? "km/h" : "mph" }
    public var distanceSuffix: String { self == .metric ? "km" : "mi" }

    /// METOD M6: the first scale ends at 60 km/h or 40 mph; it grows from there (Dial, BESLUT B16).
    public var baseScaleMax: Double { self == .metric ? 60 : 40 }

    public func speed(fromMetersPerSecond v: Double) -> Double { v / metersPerSecondPerUnit }
    public func distance(fromMeters m: Double) -> Double { m / metersPerDistanceUnit }
}
