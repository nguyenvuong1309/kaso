import KasoWidgetShared
import SwiftUI

@main
struct KasoWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityCoordinator()

    var body: some Scene {
        WindowGroup {
            WatchRootView(snapshot: connectivity.snapshot)
                .onAppear {
                    connectivity.start()
                }
        }
    }
}
