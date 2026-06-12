import UIKit

/// Custom presentation controller that manages the dimming view,
/// presented view frame, and background tap-to-dismiss.
final class NavigatorPresentationController: UIPresentationController {

    // MARK: - Properties
    let configuration: NavigatorConfiguration

    /// The dimming view behind the presented content. The view's `alpha`
    /// is animated 0 → `configuration.backgroundOverlayOpacity` during
    /// presentation, so the background color is set fully opaque and
    /// alpha controls the final intensity.
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = configuration.backgroundOverlayColor
        view.alpha = 0

        if configuration.backgroundTapDismissEnabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
            view.addGestureRecognizer(tap)
        }
        return view
    }()

    // MARK: - Init

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        configuration: NavigatorConfiguration
    ) {
        self.configuration = configuration
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    // MARK: - Frame Calculation

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerBounds = containerView?.bounds else { return .zero }

        let resolvedSize = resolveSize(configuration.size, in: containerBounds.size)

        // Center alignment: always place the view in the center of the container.
        if configuration.alignment == .center {
            return CGRect(
                x: (containerBounds.width - resolvedSize.width) / 2,
                y: (containerBounds.height - resolvedSize.height) / 2,
                width: resolvedSize.width,
                height: resolvedSize.height
            )
        }

        // Edge alignment: stick the view to the edge it slides in from.
        switch configuration.direction {
        case .left:
            return CGRect(
                x: 0,
                y: (containerBounds.height - resolvedSize.height) / 2,
                width: resolvedSize.width,
                height: resolvedSize.height
            )
        case .right:
            return CGRect(
                x: containerBounds.width - resolvedSize.width,
                y: (containerBounds.height - resolvedSize.height) / 2,
                width: resolvedSize.width,
                height: resolvedSize.height
            )
        case .top:
            return CGRect(
                x: (containerBounds.width - resolvedSize.width) / 2,
                y: 0,
                width: resolvedSize.width,
                height: resolvedSize.height
            )
        case .bottom:
            return CGRect(
                x: (containerBounds.width - resolvedSize.width) / 2,
                y: containerBounds.height - resolvedSize.height,
                width: resolvedSize.width,
                height: resolvedSize.height
            )
        }
    }

    // MARK: - Presentation Lifecycle

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)

        let targetAlpha = configuration.backgroundOverlayOpacity
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = targetAlpha
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = targetAlpha
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            containerView?.viewWithTag(NavigatorTransitionAnimator.shadowWrapperTag)?.removeFromSuperview()
            dimmingView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero

        // Do not fight an in-flight transform animation. Setting `frame`
        // while `transform` is non-identity is undefined per Apple's docs
        // and would cause the slide animation to jump. Once the animator
        // restores `transform = .identity` it's safe to update the frame
        // again (e.g. on rotation).
        guard let presentedView else { return }

        let shadowWrapper = containerView?.viewWithTag(NavigatorTransitionAnimator.shadowWrapperTag)

        if let shadowWrapper, shadowWrapper.transform.isIdentity {
            shadowWrapper.frame = frameOfPresentedViewInContainerView
            presentedView.frame = shadowWrapper.bounds
        } else if presentedView.transform.isIdentity {
            presentedView.frame = frameOfPresentedViewInContainerView
        }
    }

    // MARK: - Actions

    @objc private func dimmingViewTapped() {
        presentedViewController.dismiss(animated: true)
    }

    // MARK: - Size Resolution

    /// Defers per-axis math to `PresentationSize.Dimension.resolve(in:)`,
    /// which honors any `max` / `min` clamps configured on the dimension.
    private func resolveSize(_ size: PresentationSize, in container: CGSize) -> CGSize {
        CGSize(
            width: size.width.resolve(in: container.width),
            height: size.height.resolve(in: container.height)
        )
    }
}
