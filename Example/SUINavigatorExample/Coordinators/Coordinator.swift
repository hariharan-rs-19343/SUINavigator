import Foundation

/// Common contract for any coordinator in the app.
///
/// A coordinator owns the *navigation logic* of a feature or flow. Views
/// stay declarative and dumb — they call methods on (or invoke callbacks
/// supplied by) a coordinator rather than flipping `@State` flags
/// themselves. Coordinators decide:
///
/// 1. Which screen comes next.
/// 2. How it's presented (which `NavigatorConfiguration`).
/// 3. When the flow completes — at which point they tell their parent
///    so they can be deallocated.
///
/// This file intentionally keeps the protocol minimal. Specific
/// coordinators (`AppCoordinator`, `ShopFlowCoordinator`, …) layer their
/// own routing methods on top.
@MainActor
protocol Coordinator: AnyObject {
    /// Performs the coordinator's initial action — usually presenting
    /// the first screen of its flow. Called once by the parent right
    /// after the coordinator is created and added as a child.
    func start()
}
