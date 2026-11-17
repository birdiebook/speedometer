import SwiftUI
import UIKit

@main
struct SpeedometerApp: App {
    @StateObject private var store = TripStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            root
                .onChange(of: scenePhase, initial: true) { _, phase in
                    #if DEBUG
                    if DemoMode.name != nil { return } // demo: no store, no location
                    #endif
                    let active = phase == .active
                    // BESLUT B6: the screen stays on while the app is open.
                    UIApplication.shared.isIdleTimerDisabled = active
                    // BESLUT B10: location only while the app is active.
                    if active { store.activate() } else { store.deactivate() }
                }
        }
    }

    @ViewBuilder
    private var root: some View {
        #if DEBUG
        if let demo = DemoMode.name {
            DemoView(name: demo)
        } else {
            ContentView(store: store)
        }
        #else
        ContentView(store: store)
        #endif
    }
}
