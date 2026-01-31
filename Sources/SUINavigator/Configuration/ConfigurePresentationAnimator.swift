//
//  ConfigurePresentationAnimator.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/01/25.
//

import SwiftUI

/// Configuration for presentation animation
/// - backgroundColor: The background color during presentation
/// - springDamping: The damping ratio for the spring animation
/// - springVelocity: The initial velocity for the spring animation
/// Default values are provided for common use cases.
/// - backgroundColor: Default is a semi-transparent black color
/// - springDamping: Default is 0.8
/// - springVelocity: Default is 0.5
internal class ConfigurePresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval = 0.4
    
    // MARK: DEPENDENCIES
    private let isPresentation: Bool
    private let direction: UIRectEdge
    private let configuration: PresentationAnimationConfig
    
    init(
        isPresentation: Bool,
        direction: UIRectEdge,
        configuration: PresentationAnimationConfig = .default
    ) {
        self.isPresentation = isPresentation
        self.direction = direction
        self.configuration = configuration
    }
    
    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.viewController(forKey: .from),
              let toView = context.viewController(forKey: .to)
        else {
            return context.completeTransition(false)
        }
        
        let containerView = context.containerView
        
        if isPresentation {
            containerView.addSubview(toView.view)
            setPresentationDirection(on: toView.view, containerView: containerView)
            performPresentationAnimation(context, containerView: containerView, toView: toView)
        }else {
            performDismissalAnimation(context, containerView: containerView, fromView: fromView)
        }
    }
    
    private func setPresentationDirection(on view: UIView, containerView: UIView) {
        switch direction {
        case .left:
            view.frame = containerView.bounds.offsetBy(dx: -containerView.bounds.width, dy: 0)
        case .right:
            view.frame = containerView.bounds.offsetBy(dx: containerView.bounds.width, dy: 0)
        case .bottom:
            view.frame = containerView.bounds.offsetBy(dx: 0, dy: containerView.bounds.height)
        case .top:
            view.frame = containerView.bounds.offsetBy(dx: 0, dy: -containerView.bounds.height)
        default:
            view.frame = .zero
        }
    }
    
    private func performPresentationAnimation(_ context: UIViewControllerContextTransitioning, containerView: UIView, toView: UIViewController) {
        toView.view.alpha = 0
        let backgroundAnimation = createBackgroundAnimation(isPresenting: true)
        toView.view.layer.add(backgroundAnimation, forKey: "backgroundColor")
        
        animateWithSpring(duration: duration) {
            toView.view.frame = containerView.bounds
            toView.view.alpha = 1
        } completion: { finished in
            context.completeTransition(finished)
        }
    }
    
    private func performDismissalAnimation(_ context: UIViewControllerContextTransitioning, containerView: UIView, fromView: UIViewController) {
        let backgroundAnimation = createBackgroundAnimation(isPresenting: false)
        fromView.view.layer.add(backgroundAnimation, forKey: "backgroundColor")
        
        animateWithSpring(duration: duration) { [weak self] in
            guard let self else { return }
            fromView.view.frame = (direction == .left || direction == .right) ? containerView.bounds.offsetBy(dx: containerView.bounds.width, dy: 0) : containerView.bounds.offsetBy(dx: 0, dy: containerView.bounds.height)
            fromView.view.alpha = 0
        } completion: { finished in
            context.completeTransition(finished)
        }
    }
    
    private func setDismissDirection(on view: UIView, containerView: UIView) {
        switch direction {
        case .left:
            view.frame = containerView.bounds.offsetBy(dx: containerView.bounds.width, dy: 0)
        case .right:
            view.frame = containerView.bounds.offsetBy(dx: -containerView.bounds.width, dy: 0)
        case .bottom:
            view.frame = containerView.bounds.offsetBy(dx: 0, dy: -containerView.bounds.height)
        case .top:
            view.frame = containerView.bounds.offsetBy(dx: 0, dy: containerView.bounds.height)
        default:
            view.frame = .zero
        }
    }
    
    private func createBackgroundAnimation(isPresenting: Bool) -> CABasicAnimation {
        let backgroundAnimation = CASpringAnimation(keyPath: "backgroundColor")
        backgroundAnimation.duration = duration
        backgroundAnimation.fillMode = .forwards
        backgroundAnimation.isRemovedOnCompletion = false
        
        backgroundAnimation.fromValue = isPresenting ? UIColor.clear.cgColor : configuration.backgroundColor.cgColor
        backgroundAnimation.toValue = isPresenting ? configuration.backgroundColor.cgColor : UIColor.clear.cgColor
        return backgroundAnimation
    }
    
    private func animateWithSpring(duration: TimeInterval, _ animation: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: configuration.springDamping,
            initialSpringVelocity: configuration.springVelocity,
            options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction],
            animations: animation,
            completion: completion
        )
    }
}
