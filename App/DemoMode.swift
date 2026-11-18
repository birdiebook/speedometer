#if DEBUG
import SwiftUI
import SpeedKit

/// Debug-only screenshot mode: `-demo <riding|paused|finding|locationOff|fast>` draws the screen with fixed values,
/// with no store and no location. Compiled out of Release, so the shipped app has no such path.
enum DemoMode {
    static var name: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-demo"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}

struct DemoView: View {
    let name: String

    private let trip = Trip(distance: 12_400, movingTime: 2052, maxSpeed: 11.472)
    /// A high-speed train at 300 km/h with a max of 320: the scale is lit up to 500 (BESLUT B16).
    private let fastTrip = Trip(distance: 245_000, movingTime: 3240, maxSpeed: 88.9)

    private var unit: SpeedUnit {
        let system = Locale.current.measurementSystem
        return (system == .us || system == .uk) ? .imperial : .metric
    }

    var body: some View {
        switch name {
        case "paused":
            SpeedometerScreen(speed: 0, state: .paused, trip: trip, unit: unit, locationOff: false)
        case "finding":
            SpeedometerScreen(speed: nil, state: .findingGPS, trip: Trip(), unit: unit, locationOff: false)
        case "locationOff":
            SpeedometerScreen(speed: nil, state: .findingGPS, trip: Trip(), unit: unit, locationOff: true)
        case "fast":
            SpeedometerScreen(speed: 83.3, state: .riding, trip: fastTrip, unit: unit, locationOff: false)
        default:
            SpeedometerScreen(speed: 7.5, state: .riding, trip: trip, unit: unit, locationOff: false)
        }
    }
}
#endif
