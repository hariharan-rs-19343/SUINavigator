import UIKit

/// Custom animated transitioning that slides the presented view controller
/// in/out from the configured direction.
final class NavigatorTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Constants

    static let shadowWrapperTag = 78_421

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

        let shadowWrapper = ShadowWrapperView(frame: finalFrame)
        shadowWrapper.tag = Self.shadowWrapperTag
        configureShadowWrapper(shadowWrapper)

        toView.frame = shadowWrapper.bounds
        applyContentStyling(to: toView)
        shadowWrapper.addSubview(toView)

        shadowWrapper.transform = offScreenTransform(for: finalFrame, in: containerView.bounds)
        containerView.addSubview(shadowWrapper)

        // Force SwiftUI's first layout pass to happen NOW, while the view
        // is still off-screen. Without this you can see content "pop in"
        // mid-slide because SwiftUI's hosting view is still resolving its
        // body during the first few animation frames.
        shadowWrapper.layoutIfNeeded()

        let duration = transitionDuration(using: context)
        animateWithSpring(duration: duration, animations: {
            shadowWrapper.transform = .identity
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

        let wrapper = fromView.superview?.tag == Self.shadowWrapperTag
            ? fromView.superview!
            : fromView

        let containerView = context.containerView
        let targetTransform = offScreenTransform(
            for: wrapper.frame, in: containerView.bounds
        )

        let duration = transitionDuration(using: context) * 0.85
        animateWithSpring(duration: duration, animations: {
            wrapper.transform = targetTransform
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

    // MARK: - Styling

    /// Configures the shadow wrapper with shadow properties and adaptive border.
    private func configureShadowWrapper(_ wrapper: ShadowWrapperView) {
        wrapper.backgroundColor = .clear
        wrapper.clipsToBounds = false

        let corners = resolvedMaskedCorners()
        wrapper.layer.cornerRadius = configuration.cornerRadius
        wrapper.layer.maskedCorners = corners

        wrapper.layer.shadowColor = UIColor.shadowColor.cgColor
        wrapper.layer.shadowOpacity = 0.2
        wrapper.layer.shadowOffset = .zero
        wrapper.layer.shadowRadius = 4
        wrapper.layer.shadowPath = UIBezierPath(
            roundedRect: wrapper.bounds,
            cornerRadius: configuration.cornerRadius
        ).cgPath

        wrapper.layer.borderWidth = 1.0
        wrapper.updateBorderColor()
    }

    /// Applies corner radius and clipping to the content view (presented view).
    private func applyContentStyling(to view: UIView) {
        view.layer.cornerRadius = configuration.cornerRadius
        view.layer.maskedCorners = resolvedMaskedCorners()
        view.clipsToBounds = true
    }

    private func resolvedMaskedCorners() -> CACornerMask {
        if configuration.alignment == .center {
            return [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                    .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        return maskedCorners(for: configuration.direction)
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

// MARK: - Shadow Wrapper View

/// A transparent container view that carries shadow and border properties,
/// allowing the content view inside to use `clipsToBounds = true` for
/// corner radius clipping without hiding the shadow.
private final class ShadowWrapperView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
        updateBorderColor()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateBorderColor()
        }
    }

    func updateBorderColor() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        let color: UIColor = isDark
            ? UIColor.gray.withAlphaComponent(0.2)
            : UIColor.black.withAlphaComponent(0.12)
        layer.borderColor = color.cgColor
    }
}
