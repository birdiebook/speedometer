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
                    // BESLUT B6: the screen stays on while the app is open.
                    UIApplication.shared.isIdleTimerDisabled = phase == .active
                    // BESLUT B17: during a ride the location is read on in the background.
                    switch phase {
                    case .active: store.activate()
                    case .background: store.enterBackground()
                    default: break // inactive is a moment between the two (control centre, app switcher)
                    }
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
