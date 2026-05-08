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

    /// A dimension that can be expressed as a fixed value, a fraction of
    /// the parent container, or the full extent — optionally clamped to
    /// `min` / `max` point values.
    ///
    /// The `min` / `max` clamps are useful on iPad and Mac Catalyst,
    /// where a `.fraction(0.8)` would otherwise grow unboundedly as the
    /// window widens. For a "card" presentation that should keep growing
    /// with the window only up to a point:
    ///
    /// ```swift
    /// .fraction(0.8, max: 720)
    /// // or fluently:
    /// .fraction(0.8).max(720)
    /// ```
    public struct Dimension: Sendable, Equatable {

        fileprivate enum Base: Sendable, Equatable {
            case fixed(CGFloat)
            case fraction(CGFloat)
            case full
        }

        fileprivate let base: Base
        fileprivate let maxPoints: CGFloat?
        fileprivate let minPoints: CGFloat?

        fileprivate init(base: Base, max: CGFloat? = nil, min: CGFloat? = nil) {
            self.base = base
            self.maxPoints = max
            self.minPoints = min
        }

        // MARK: Factories

        /// A fixed point value.
        public static func fixed(_ value: CGFloat) -> Dimension {
            Dimension(base: .fixed(value))
        }

        /// A fraction of the container's corresponding axis (`0.0 – 1.0`),
        /// optionally capped at a maximum point value.
        public static func fraction(_ ratio: CGFloat, max: CGFloat? = nil) -> Dimension {
            Dimension(base: .fraction(ratio), max: max)
        }

        /// Occupies the full container extent on this axis.
        public static let full = Dimension(base: .full)

        /// Occupies the full container extent on this axis but capped at
        /// a maximum point value.
        public static func full(max: CGFloat) -> Dimension {
            Dimension(base: .full, max: max)
        }

        // MARK: Fluent constraints

        /// Returns a copy of this dimension constrained to never exceed
        /// `value` points (regardless of the container extent).
        public func max(_ value: CGFloat) -> Dimension {
            Dimension(base: base, max: value, min: minPoints)
        }

        /// Returns a copy of this dimension constrained to be at least
        /// `value` points (subject to the available container extent).
        public func min(_ value: CGFloat) -> Dimension {
            Dimension(base: base, max: maxPoints, min: value)
        }

        // MARK: Resolution

        /// Resolves this dimension against the available container extent.
        /// Used by `NavigatorPresentationController` when computing the
        /// presented view's frame.
        func resolve(in available: CGFloat) -> CGFloat {
            let raw: CGFloat
            switch base {
            case .fixed(let v):
                raw = v
            case .fraction(let r):
                raw = available * Swift.max(0, Swift.min(r, 1))
            case .full:
                raw = available
            }
            var result = raw
            if let cap = maxPoints {
                result = Swift.min(result, cap)
            }
            if let floor = minPoints {
                result = Swift.max(result, floor)
            }
            // Never exceed what's actually available.
            return Swift.min(result, available)
        }
    }

    /// Creates a presentation size with the given width and height dimensions.
    public init(width: Dimension, height: Dimension) {
        self.width = width
        self.height = height
    }

    // MARK: Presets

    /// Full-screen presentation.
    public static let fullScreen = PresentationSize(width: .full, height: .full)

    /// Compact half-sheet — full container width (capped at 720 pt) by
    /// 50 % container height.
    ///
    /// The size used by ``NavigatorConfiguration/bottomSheet``. Designed
    /// for *contextual* sheets: pickers, brief detail panels,
    /// confirmation prompts, action lists. For substantial content
    /// (forms, settings, multi-page flows) prefer ``sheet``.
    ///
    /// ## Sizing across containers
    ///
    /// | Container | Width | Height |
    /// |---|---|---|
    /// | iPhone (393 × 852) | 393 | 426 |
    /// | iPad portrait (834 × 1194) | 720 (capped) | 597 |
    /// | iPad landscape (1194 × 834) | 720 (capped) | 417 |
    /// | Mac Catalyst (1440 × 900) | 720 (capped) | 450 |
    ///
    /// - SeeAlso: ``sheet`` (taller, fixed-width variant)
    public static let halfSheet = PresentationSize(
        width: .full(max: 720),
        height: .fraction(0.5)
    )

    /// Side panel (40 % width, full height). Width capped at 480 pt for
    /// reasonable proportions on large windows.
    public static let sidePanel = PresentationSize(
        width: .fraction(0.4, max: 480),
        height: .full
    )

    /// Compact card (80 % width, 60 % height) capped at 720 × 920 so it
    /// stops growing on iPad split-view and Mac Catalyst large windows.
    public static let card = PresentationSize(
        width: .fraction(0.8, max: 1240),
        height: .fraction(0.65, max: 840)
    )
    
    /// Tall, fixed-max-width sheet — wider than ``card`` and substantially
    /// taller than ``halfSheet``.
    ///
    /// Width is **fixed at 860 pt** (clamped down to the container on
    /// smaller windows), and height is 76 % of the container up to a
    /// 960-pt cap. The size used by ``NavigatorConfiguration/sheet``.
    ///
    /// Use this when the modal needs significant vertical room — settings
    /// screens, multi-page forms, content viewers — and should look
    /// natural across phones *and* large windows without spanning the
    /// entire window on iPad / Mac Catalyst.
    ///
    /// ## Sizing across containers
    ///
    /// | Container | Width | Height |
    /// |---|---|---|
    /// | iPhone (393 × 852) | 393 (clamped to available) | 647 |
    /// | iPad portrait (834 × 1194) | 834 (clamped) | 907 |
    /// | iPad landscape (1194 × 834) | 860 | 634 |
    /// | Mac Catalyst (1440 × 900) | 860 | 684 |
    /// | Mac Catalyst (1800 × 1200) | 860 | 912 |
    /// | Theoretical (any wider) | 860 (capped) | 960 (capped) |
    ///
    /// > Tip: For a "fluid" sheet that grows with the window up to a
    /// > maximum, prefer `.full(max: 860)` over `.fixed(860)`. The two
    /// > resolve to identical numeric values, but `.full(max:)` reads
    /// > the intent more clearly.
    ///
    /// - SeeAlso: ``halfSheet``, ``card``,
    ///   ``NavigatorConfiguration/sheet``
    public static let sheet = PresentationSize(
        width: .fixed(860),
        height: .fraction(0.76, max: 960)
    )
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
