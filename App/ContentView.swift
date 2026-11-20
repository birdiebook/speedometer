import SwiftUI
import SpeedKit

/// Connects the store to the screen and adds the long-press reset (BESLUT B6), the menu (B14) and Trail (B16).
struct ContentView: View {
    @ObservedObject var store: TripStore
    @State private var sheet: Sheet?

    /// BESLUT B14: one sheet at a time; switching from the menu to Trail closes the menu and opens Trail.
    enum Sheet: Identifiable {
        case menu, trail
        var id: Self { self }
    }

    var body: some View {
        SpeedometerScreen(
            speed: store.displayedSpeed,
            state: store.state,
            trip: store.trip,
            unit: store.unit,
            locationOff: store.locationOff,
            onMenu: { sheet = .menu }
        )
        .contentShape(Rectangle())
        // BESLUT B6: hold anywhere for about 0.8 s to reset, with a haptic.
        .onLongPressGesture(minimumDuration: 0.8) {
            store.reset()
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: store.resetCount)
        .sheet(item: $sheet) { which in
            switch which {
            case .menu:
                MenuSheet(onTrail: { sheet = .trail })
            case .trail:
                // BESLUT B16: live while open; swipe down to close.
                TrailScreen(trail: store.trail, trip: store.trip, unit: store.unit)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Theme.background)
            }
        }
    }
}
