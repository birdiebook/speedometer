import SwiftUI
import UIKit

@main
struct SpeedometerApp: App {
    @StateObject private var store = TripStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    let active = phase == .active
                    // BESLUT B6: the screen stays on while the app is open.
                    UIApplication.shared.isIdleTimerDisabled = active
                    // BESLUT B10: location only while the app is active.
                    if active { store.activate() } else { store.deactivate() }
                }
        }
    }
}
