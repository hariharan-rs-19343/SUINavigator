//
//  ModalPresentationConfig.swift
//  MEAdmin
//
//  Created by Hariharan R S on 25/09/25.
//

import UIKit
import SUICore

/// Configuration for modal presentation settings.
/// This struct defines the maximum width, maximum height, and corner radius for modally presented views.
/// Default values are provided for common use cases.
/// - maxWidth: The maximum width of the modal view. Default is 960 points.
/// - maxHeight: The maximum height of the modal view. Default is 70% of the screen height.
/// - cornerRadius: The corner radius of the modal view. Default is 10 points.

public struct ModalPresentationConfig {
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    
    public init(maxWidth: CGFloat, maxHeight: CGFloat, cornerRadius: CGFloat) {
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
    }
    
    @MainActor public static let `default` = ModalPresentationConfig(
        maxWidth: 960,
        maxHeight: UIScreen.screenHeight * 0.7,
        cornerRadius: 10
    )
}
