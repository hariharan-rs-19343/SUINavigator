//
//  PresentationAnimationConfig.swift
//  MEAdmin
//
//  Created by Hariharan R S on 25/09/25.
//

import UIKit

/// Configuration for presentation animations.
/// Includes background color, spring damping, and spring velocity.
/// Default values are provided.
/// - backgroundColor: The color of the background during the presentation.
/// - springDamping: The damping ratio for the spring animation.
/// - springVelocity: The initial velocity of the spring animation.
public struct PresentationAnimationConfig {
    let backgroundColor: UIColor
    let springDamping: CGFloat
    let springVelocity: CGFloat
    
    public init(backgroundColor: UIColor, springDamping: CGFloat, springVelocity: CGFloat) {
        self.backgroundColor = backgroundColor
        self.springDamping = springDamping
        self.springVelocity = springVelocity
    }
    
    @MainActor
    public static let `default` = PresentationAnimationConfig(
        backgroundColor: UIColor.systemBackground.withAlphaComponent(0.40),
        springDamping: 0.8,
        springVelocity: 0
    )
}
