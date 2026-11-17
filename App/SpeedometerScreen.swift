import SwiftUI
import UIKit
import SpeedKit

/// The whole screen (BESLUT B5, B6): dial, big number, the three numbers and the hint line.
/// Plain values in, no store, so it can be drawn with fake values.
struct SpeedometerScreen: View {
    let speed: Double?
    let state: TripState
    let trip: Trip
    let unit: SpeedUnit
    let locationOff: Bool

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                DialView(speed: speed, state: state, maxSpeed: trip.maxSpeed, unit: unit, locationOff: locationOff,
                         screenWidth: geo.size.width, tripStarted: !trip.isEmpty)
                    .frame(maxHeight: .infinity)
                Rectangle().fill(Theme.separator).frame(height: 1)
                    .padding(.top, 16)
                numbers
                    .padding(.top, 18)
                hint
                    .frame(height: 20)
                    .padding(.top, 18)
            }
            .padding(.horizontal, 25)
            // FORM.md: 56 pt at the bottom, counted from the screen edge, so the home indicator's inset is part of it.
            .padding(.bottom, max(0, 56 - geo.safeAreaInsets.bottom))
            .padding(.top, 8)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var numbers: some View {
        HStack(alignment: .top, spacing: 12) {
            stat("DISTANCE", Format.distance(trip.distance, unit: unit), unit.distanceSuffix)
            stat("TIME", Format.duration(trip.movingTime), nil)
            stat("AVG", Format.averageSpeed(trip.averageSpeed, unit: unit), trip.averageSpeed == nil ? nil : unit.speedSuffix)
        }
    }

    private func stat(_ label: String, _ value: String, _ suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium)).tracking(1.5)
                .foregroundStyle(Theme.label)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .medium))
                    .monospacedDigit() // BESLUT B11
                    .foregroundStyle(Theme.primary)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.label)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A fixed slot, so the numbers above do not move between modes.
    @ViewBuilder
    private var hint: some View {
        if locationOff, let url = URL(string: UIApplication.openSettingsURLString) {
            Link("Allow location in Settings", destination: url)
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
        } else if state == .paused && !trip.isEmpty { // BESLUT B15
            Text("Hold to reset")
                .font(.system(size: 13))
                .foregroundStyle(Theme.label)
        } else {
            Color.clear
        }
    }
}

private let previewTrip = Trip(distance: 12_400, movingTime: 2052, maxSpeed: 45 / 3.6)

#Preview("Riding") {
    SpeedometerScreen(speed: 36 / 3.6, state: .riding, trip: previewTrip, unit: .metric, locationOff: false)
}

#Preview("Paused") {
    SpeedometerScreen(speed: 0.3, state: .paused, trip: previewTrip, unit: .metric, locationOff: false)
}

#Preview("Finding GPS") {
    SpeedometerScreen(speed: nil, state: .findingGPS, trip: Trip(), unit: .metric, locationOff: false)
}

#Preview("Location off") {
    SpeedometerScreen(speed: nil, state: .findingGPS, trip: Trip(), unit: .metric, locationOff: true)
}

#Preview("Riding, mph") {
    SpeedometerScreen(speed: 8.9408, state: .riding, trip: previewTrip, unit: .imperial, locationOff: false)
}
