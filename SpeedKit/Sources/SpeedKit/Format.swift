import Foundation

/// METOD M7: formatting by hand, so the phone's locale never changes the text (BESLUT B8).
public enum Format {
    public static let placeholder = "\u{2013}" // en dash, FORM.md

    /// The big number: an integer, or the dash when there is no speed.
    public static func speed(_ metersPerSecond: Double?, unit: SpeedUnit) -> String {
        guard let v = metersPerSecond else { return placeholder }
        return String(Int(unit.speed(fromMetersPerSecond: max(v, 0)).rounded()))
    }

    /// One decimal with a dot, in kilometres or miles.
    public static func distance(_ meters: Double, unit: SpeedUnit) -> String {
        oneDecimal(unit.distance(fromMeters: max(meters, 0)))
    }

    /// The average speed with one decimal, or the dash before any moving time.
    public static func averageSpeed(_ metersPerSecond: Double?, unit: SpeedUnit) -> String {
        guard let v = metersPerSecond else { return placeholder }
        return oneDecimal(unit.speed(fromMetersPerSecond: max(v, 0)))
    }

    /// `m:ss` under an hour, otherwise `h:mm:ss`.
    public static func duration(_ seconds: Double) -> String {
        let total = Int(max(seconds, 0).rounded(.down))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let ss = s < 10 ? "0\(s)" : "\(s)"
        if h > 0 {
            let mm = m < 10 ? "0\(m)" : "\(m)"
            return "\(h):\(mm):\(ss)"
        }
        return "\(m):\(ss)"
    }

    static func oneDecimal(_ x: Double) -> String {
        let tenths = Int((x * 10).rounded())
        return "\(tenths / 10).\(tenths % 10)"
    }
}
