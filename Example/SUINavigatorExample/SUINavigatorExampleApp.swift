import SwiftUI
import SUINavigator

@main
struct SUINavigatorExampleApp: App {

    /// Single source of truth for app-level navigation. Owns the shared
    /// `Navigator` and any in-flight child coordinators.
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                // Expose the navigator separately so the direct-API demos
                // (Built-in Presets, Imperative API, etc.) can still
                // resolve `@EnvironmentObject Navigator` without going
                // through the coordinator.
                .environmentObject(coordinator.navigator)
        }
    }
}
