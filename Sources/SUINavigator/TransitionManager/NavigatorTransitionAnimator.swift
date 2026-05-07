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

        // Position the view at its final frame and translate it off-screen
        // via `transform`. Animating `transform` is GPU-composited and does
        // NOT invalidate layout — meaningfully smoother than animating
        // `frame`, which forces UIHostingController/SwiftUI through a
        // layout pass on every animation tick.
        toView.frame = finalFrame
        applyStyling(to: toView)
        toView.transform = offScreenTransform(for: finalFrame, in: containerView.bounds)
        containerView.addSubview(toView)

        // Force SwiftUI's first layout pass to happen NOW, while the view
        // is still off-screen. Without this you can see content "pop in"
        // mid-slide because SwiftUI's hosting view is still resolving its
        // body during the first few animation frames.
        toView.layoutIfNeeded()

        // Spring physics; tunable per-configuration via `springDamping`
        // / `springVelocity`. Default damping of 1.0 is critically damped
        // (no overshoot, no perceived duration stretch).
        let duration = transitionDuration(using: context)
        animateWithSpring(duration: duration, animations: {
            toView.transform = .identity
        }) { _ in
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
        let targetTransform = offScreenTransform(
            for: fromView.frame, in: containerView.bounds
        )

        // Dismissal runs a touch faster than the presentation so the view
        // feels "thrown out" rather than "eased out". Spring values come
        // from the same configuration knobs used on present.
        let duration = transitionDuration(using: context) * 0.85
        animateWithSpring(duration: duration, animations: {
            fromView.transform = targetTransform
        }) { _ in
            context.completeTransition(!context.transitionWasCancelled)
        }
    }

    // MARK: - Helpers

    /// Spring-driven `UIView.animate` wrapper used by both presentation
    /// and dismissal. `.curveLinear` is intentional — when a spring is
    /// supplied UIKit derives the timing curve from physics and ignores
    /// the option, so passing `.curveLinear` makes the intent explicit.
    private func animateWithSpring(
        duration: TimeInterval,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: configuration.springDamping,
            initialSpringVelocity: configuration.springVelocity,
            options: [.beginFromCurrentState, .curveLinear, .allowUserInteraction],
            animations: animations,
            completion: completion
        )
    }

    /// Returns the affine translation that moves a view sitting at `frame`
    /// fully off-screen in the configured direction.
    private func offScreenTransform(for frame: CGRect, in containerBounds: CGRect) -> CGAffineTransform {
        switch configuration.direction {
        case .left:
            return CGAffineTransform(translationX: -frame.maxX, y: 0)
        case .right:
            return CGAffineTransform(translationX: containerBounds.width - frame.minX, y: 0)
        case .top:
            return CGAffineTransform(translationX: 0, y: -frame.maxY)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: containerBounds.height - frame.minY)
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
