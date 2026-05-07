import SwiftUI
import SUINavigator

/// Root coordinator for the example app.
///
/// Owns the single shared `Navigator` instance and tracks any in-flight
/// child coordinators (subflows). Inject as an `@EnvironmentObject` at
/// the scene root; expose `navigator` separately if other code wants
/// direct API access.
///
/// ```swift
/// @main
/// struct App: App {
///     @StateObject private var coordinator = AppCoordinator()
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environmentObject(coordinator)
///                 .environmentObject(coordinator.navigator)
///         }
///     }
/// }
/// ```
@MainActor
final class AppCoordinator: Coordinator, ObservableObject {

    // MARK: - Properties

    /// The single `Navigator` shared across all coordinators in this app.
    /// Children receive it through their initializer rather than reading
    /// it from the environment, because `Navigator.present(...)` builds
    /// the destination view tree outside the SwiftUI environment.
    let navigator: Navigator

    /// Active child coordinators retained for the duration of their flow.
    /// Held strongly so they don't deallocate while their callbacks
    /// (captured `[weak self]`) are still on the stack.
    @Published private(set) var children: [any Coordinator] = []

    // MARK: - Init

    init(navigator: Navigator = Navigator()) {
        self.navigator = navigator
    }

    // MARK: - Coordinator

    /// The root view is shown by the App scene, so there's nothing to
    /// present here. Implemented to satisfy the protocol.
    func start() {}

    // MARK: - Top-level routes

    /// One-step flow: open a product detail and close it.
    /// Demonstrates the simplest possible coordinator-driven presentation.
    func openProductDetail(_ product: Product) {
        navigator.present(configuration: .centerCard) { [weak self] in
            ShopProductDetailScreen(
                product: product,
                onBuy: nil,                                       // single-step demo
                onClose: { [weak self] in self?.navigator.dismiss() }
            )
        }
    }

    /// Multi-step flow: hand control to a `ShopFlowCoordinator` that
    /// orchestrates detail → checkout → finish. This is where the
    /// coordinator pattern earns its keep — the AppCoordinator stops
    /// caring about the inner steps and only knows when the flow ends.
    func startShopFlow(for product: Product) {
        let flow = ShopFlowCoordinator(
            navigator: navigator,
            product: product,
            onFinish: { [weak self] coord in
                self?.removeChild(coord)
            }
        )
        addChild(flow)
        flow.start()
    }

    /// Imperative dismissal of whatever is currently presented.
    func dismiss() {
        navigator.dismiss()
    }

    // MARK: - Children

    private func addChild(_ coord: any Coordinator) {
        children.append(coord)
    }

    private func removeChild(_ coord: any Coordinator) {
        children.removeAll { $0 === coord }
    }
}
