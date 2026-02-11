import UIKit

/// Custom presentation controller that manages the dimming view,
/// presented view frame, and background tap-to-dismiss.
final class NavigatorPresentationController: UIPresentationController {

    // MARK: - Properties
    let configuration: NavigatorConfiguration

    /// The dimming view behind the presented content.
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.065)
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

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
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
            dimmingView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    // MARK: - Actions

    @objc private func dimmingViewTapped() {
        presentedViewController.dismiss(animated: true)
    }

    // MARK: - Size Resolution

    private func resolveDimension(_ dimension: PresentationSize.Dimension, in available: CGFloat) -> CGFloat {
        switch dimension {
        case .fixed(let value):
            return min(value, available)
        case .fraction(let ratio):
            return available * max(0, min(ratio, 1))
        case .full:
            return available
        }
    }

    private func resolveSize(_ size: PresentationSize, in container: CGSize) -> CGSize {
        CGSize(
            width: resolveDimension(size.width, in: container.width),
            height: resolveDimension(size.height, in: container.height)
        )
    }
}
