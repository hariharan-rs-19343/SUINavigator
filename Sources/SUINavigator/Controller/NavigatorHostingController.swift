import SwiftUI
import UIKit

/// A `UIHostingController` subclass used to present SwiftUI views
/// through UIKit's presentation system.
///
/// It stores a strong reference to the transitioning delegate so that
/// it stays alive for the full presentation lifecycle.
final class NavigatorHostingController<Content: View>: UIHostingController<Content> {

    // MARK: - Properties

    /// Retained transitioning delegate (UIKit only keeps a weak reference).
    private var navigatorTransitioningDelegate: NavigatorTransitioningDelegate?

    /// Closure invoked when the controller is dismissed (including
    /// interactive / background-tap dismissals).
    var onDismiss: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            onDismiss?()
        }
    }

    // MARK: - Configuration

    /// Configures the hosting controller for custom presentation.
    func configure(with configuration: NavigatorConfiguration) {
        let delegate: NavigatorTransitioningDelegate = NavigatorTransitioningDelegate(configuration: configuration)
        self.navigatorTransitioningDelegate = delegate
        self.transitioningDelegate = delegate
        self.modalPresentationStyle = .custom
    }
}
