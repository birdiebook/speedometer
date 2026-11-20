#if DEBUG
import SwiftUI
import SpeedKit

/// Debug-only screenshot mode: `-demo <riding|paused|finding|locationOff|menu|trail|trailFinger>` draws the screen
/// with fixed values, with no store and no location. Compiled out of Release, so the shipped app has no such path.
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
        case "menu": // BESLUT B14
            SpeedometerScreen(speed: 7.5, state: .riding, trip: trip, unit: unit, locationOff: false, onMenu: {})
                .sheet(isPresented: .constant(true)) { MenuSheet(onTrail: {}) }
        case "trail": // BESLUT B16
            TrailScreen(trail: DemoTrail.engine.trail, trip: DemoTrail.engine.trip, unit: unit)
        case "trailFinger":
            TrailScreen(trail: DemoTrail.engine.trail, trip: DemoTrail.engine.trip, unit: unit,
                        initialSelection: DemoTrail.fingerIndex)
        default:
            SpeedometerScreen(speed: 7.5, state: .riding, trip: trip, unit: unit, locationOff: false, onMenu: {})
        }
    }
}
#endif
