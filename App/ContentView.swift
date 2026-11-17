import SwiftUI
import SpeedKit

/// Connects the store to the screen and adds the long-press reset (BESLUT B6).
struct ContentView: View {
    @ObservedObject var store: TripStore

    var body: some View {
        SpeedometerScreen(
            speed: store.displayedSpeed,
            state: store.state,
            trip: store.trip,
            unit: store.unit,
            locationOff: store.locationOff
        )
        .contentShape(Rectangle())
        // BESLUT B6: hold anywhere for about 0.8 s to reset, with a haptic.
        .onLongPressGesture(minimumDuration: 0.8) {
            store.reset()
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: store.resetCount)
    }
}
