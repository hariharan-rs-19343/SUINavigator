//
//  ConfigurableTransitionManager.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/01/25.
//

import UIKit

/// A configurable transition manager to handle custom view controller transitions.
/// This class conforms to `PresentationTransitionDelegate` and allows for custom animations during presentation and dismissal of view controllers.
/// It uses a `PresentationAnimationConfig` to define the animation parameters and a `UIRectEdge` to specify the direction of the transition.
public class ConfigurableTransitionManager: NSObject, PresentationTransitionProtocol {
    public var dismissCompletion: (() -> Void)?
    
    // MARK: Dependencies
    private let config: PresentationAnimationConfig
    private var transitionDirection: UIRectEdge
    
    public init(
        edge transitionDirection: UIRectEdge,
        config: PresentationAnimationConfig = .default
    ) {
        self.config = config
        self.transitionDirection = transitionDirection
        super.init()
    }
    
    // Default transition manager with bottom edge transition
    public static var `default`: any PresentationTransitionProtocol {
        ConfigurableTransitionManager(edge: .bottom)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return configure(animator: ConfigurePresentationAnimator(isPresentation: true, direction: transitionDirection, configuration: config))
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.dismissCompletion?()
        return configure(animator: ConfigurePresentationAnimator(isPresentation: false, direction: transitionDirection, configuration: config))
    }
    
    public func configure(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerAnimatedTransitioning {
        return animator
    }
}
