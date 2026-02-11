//
//  PresentationModels.swift
//  SUINavigator
//
//  Created by Hariharan R S on 11/02/26.
//

import UIKit

// MARK: - Presentation Direction

/// The direction from which the presented view slides into the screen.
public enum PresentationDirection: Sendable, Equatable {
    /// Slides in from the left edge.
    case left
    /// Slides in from the right edge.
    case right
    /// Slides in from the top edge.
    case top
    /// Slides in from the bottom edge.
    case bottom
}

// MARK: - Presentation Size

/// Defines the size of the presented view.
public struct PresentationSize: Sendable, Equatable {
    /// Width specification for the presented view.
    public var width: Dimension
    /// Height specification for the presented view.
    public var height: Dimension

    /// A dimension that can be expressed as a fixed value, a fraction of the
    /// parent container, or the full extent.
    public enum Dimension: Sendable, Equatable {
        /// A fixed point value.
        case fixed(CGFloat)
        /// A fraction of the container's corresponding axis (0.0 – 1.0).
        case fraction(CGFloat)
        /// Occupies the full container extent on this axis.
        case full
    }

    /// Creates a presentation size with the given width and height dimensions.
    public init(width: Dimension, height: Dimension) {
        self.width = width
        self.height = height
    }

    // MARK: Presets

    /// Full-screen presentation.
    public static let fullScreen = PresentationSize(width: .full, height: .full)

    /// Half-sheet from the bottom (full width, 50 % height).
    public static let halfSheet = PresentationSize(width: .full, height: .fraction(0.5))

    /// Side panel (40 % width, full height).
    public static let sidePanel = PresentationSize(width: .fraction(0.4), height: .full)

    /// Compact card (80 % width, 60 % height).
    public static let card = PresentationSize(width: .fraction(0.8), height: .fraction(0.6))
}

// MARK: - Presentation Alignment

/// Controls whether the presented view sticks to the direction edge
/// or is centered in the container.
public enum PresentationAlignment: Sendable, Equatable {
    /// The view sticks to the edge it slides in from (default).
    /// e.g. a bottom sheet stays at the bottom, a left panel stays at the left.
    case edge
    /// The view is centered in the container regardless of slide direction.
    /// The slide direction only controls the entry/exit animation.
    case center
}
