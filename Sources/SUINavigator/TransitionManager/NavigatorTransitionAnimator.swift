import UIKit

/// Custom animated transitioning that slides the presented view controller
/// in/out from the configured direction.
final class NavigatorTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Properties

    let configuration: NavigatorConfiguration
    let isPresenting: Bool

    // MARK: - Init

    init(configuration: NavigatorConfiguration, isPresenting: Bool) {
        self.configuration = configuration
        self.isPresenting = isPresenting
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        configuration.animationDuration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    // MARK: - Presentation

    private func animatePresentation(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to),
              let toVC = context.viewController(forKey: .to) else {
            context.completeTransition(false)
            return
        }

        let containerView = context.containerView
        let finalFrame = context.finalFrame(for: toVC)

        // Start off-screen
        toView.frame = finalFrame
        toView.frame.origin = offScreenOrigin(for: finalFrame, in: containerView.bounds)
        containerView.addSubview(toView)

        applyStyling(to: toView)

        let duration = transitionDuration(using: context)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            toView.frame = finalFrame
        } completion: { finished in
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Dismissal

    private func animateDismissal(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.view(forKey: .from) else {
            context.completeTransition(false)
            return
        }

        let containerView = context.containerView
        let offScreen = offScreenOrigin(for: fromView.frame, in: containerView.bounds)
        var targetFrame = fromView.frame
        targetFrame.origin = offScreen

        let duration = transitionDuration(using: context)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseInOut
        ) {
            fromView.frame = targetFrame
        } completion: { finished in
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Helpers

    /// Returns the origin that places the view off-screen in the configured direction.
    private func offScreenOrigin(for frame: CGRect, in containerBounds: CGRect) -> CGPoint {
        switch configuration.direction {
        case .left:
            return CGPoint(x: -frame.width, y: frame.origin.y)
        case .right:
            return CGPoint(x: containerBounds.width, y: frame.origin.y)
        case .top:
            return CGPoint(x: frame.origin.x, y: -frame.height)
        case .bottom:
            return CGPoint(x: frame.origin.x, y: containerBounds.height)
        }
    }

    /// Applies corner radius and shadow from the configuration.
    private func applyStyling(to view: UIView) {
        view.layer.cornerRadius = configuration.cornerRadius
        // Center alignment rounds all corners; edge alignment rounds only the inner corners.
        if configuration.alignment == .center {
            view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            view.layer.maskedCorners = maskedCorners(for: configuration.direction)
        }
        
        view.clipsToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 8
    }

    /// Determines which corners to round based on the slide direction.
    private func maskedCorners(for direction: PresentationDirection) -> CACornerMask {
        switch direction {
        case .bottom:
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .top:
            return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .left:
            return [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        case .right:
            return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        }
    }
}
