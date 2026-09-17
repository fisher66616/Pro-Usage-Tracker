import SwiftUI

@main
struct ProUsageTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = CounterStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(minWidth: 820, minHeight: 560)
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        store.refreshDayIfNeeded()
                    }
                }
        }
        .defaultSize(width: 1080, height: 650)
        .windowStyle(.hiddenTitleBar)
    }
}
