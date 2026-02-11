import UIKit

/// Vends the custom presentation controller and transition animators
/// for a navigator presentation.
final class NavigatorTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    // MARK: - Properties

    let configuration: NavigatorConfiguration

    // MARK: - Init

    init(configuration: NavigatorConfiguration) {
        self.configuration = configuration
        super.init()
    }

    // MARK: - UIViewControllerTransitioningDelegate

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        NavigatorPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            configuration: configuration
        )
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        NavigatorTransitionAnimator(configuration: configuration, isPresenting: true)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        NavigatorTransitionAnimator(configuration: configuration, isPresenting: false)
    }
}
