import UIKit

/// Configuration object that controls every aspect of a navigator presentation.
///
/// Use the builder pattern for easy construction:
/// ```swift
/// let config = NavigatorConfiguration.builder()
///     .direction(.left)
///     .size(.sidePanel)
///     .backgroundTapDismiss(false)
///     .cornerRadius(16)
///     .build()
/// ```
public struct NavigatorConfiguration: Equatable {

    // MARK: - Properties

    /// Direction the view slides in from.
    public let direction: PresentationDirection

    /// Size of the presented view.
    public let size: PresentationSize
    
    /// Corner radius applied to the presented view.
    public let cornerRadius: CGFloat

    /// Whether tapping the dimmed background dismisses the presented view.
    public let backgroundTapDismissEnabled: Bool

    /// Duration of the presentation / dismissal animation in seconds.
    /// Note: when spring physics are active (damping < 1) the perceived
    /// duration may exceed this value as the spring settles.
    public let animationDuration: TimeInterval

    /// Controls whether the presented view sticks to the direction edge or is centered.
    public let alignment: PresentationAlignment

    /// Spring damping ratio for the slide animation. `1.0` is critically
    /// damped (no overshoot, snappy stop). Values closer to `0.0` produce
    /// progressively bouncier landings. Clamped to `0.1...1.0` at runtime.
    public let springDamping: CGFloat

    /// Initial spring velocity, in units of the total animation distance
    /// per second. `0.0` starts from rest. Higher values give the view
    /// momentum into the animation — useful for "thrown" exits.
    public let springVelocity: CGFloat

    /// Color of the dimming overlay shown behind the presented view.
    /// Combined with `backgroundOverlayOpacity` to produce the final tint.
    public let backgroundOverlayColor: UIColor

    /// Opacity of the dimming overlay (`0.0` fully transparent, `1.0`
    /// fully opaque). The overlay's alpha animates 0 → this value during
    /// presentation. Clamped to `0.0...1.0` at runtime.
    public let backgroundOverlayOpacity: CGFloat

    // MARK: - Equatable
    public static func == (lhs: NavigatorConfiguration, rhs: NavigatorConfiguration) -> Bool {
        lhs.direction == rhs.direction
            && lhs.size == rhs.size
            && lhs.cornerRadius == rhs.cornerRadius
            && lhs.backgroundTapDismissEnabled == rhs.backgroundTapDismissEnabled
            && lhs.animationDuration == rhs.animationDuration
            && lhs.alignment == rhs.alignment
            && lhs.springDamping == rhs.springDamping
            && lhs.springVelocity == rhs.springVelocity
            && lhs.backgroundOverlayOpacity == rhs.backgroundOverlayOpacity
            && lhs.backgroundOverlayColor.isEqual(rhs.backgroundOverlayColor)
    }

    // MARK: - Builder
    /// Returns a new builder with default values.
    public static func builder() -> Builder {
        Builder()
    }

    /// Fluent builder for constructing `NavigatorConfiguration` step by step.
    public class Builder {
        private var _direction: PresentationDirection = .bottom
        private var _size: PresentationSize = .fullScreen
        private var _cornerRadius: CGFloat = 16
        private var _backgroundTapDismissEnabled: Bool = true
        private var _animationDuration: TimeInterval = 0.30
        private var _alignment: PresentationAlignment = .center
        private var _springDamping: CGFloat = 1.0
        private var _springVelocity: CGFloat = 0.0
        private var _backgroundOverlayColor: UIColor = .black
        private var _backgroundOverlayOpacity: CGFloat = 0.18

        public init() {}

        /// Sets the direction the view slides in from.
        @discardableResult
        public func direction(_ value: PresentationDirection) -> Builder {
            _direction = value
            return self
        }

        /// Sets the size of the presented view.
        @discardableResult
        public func size(_ value: PresentationSize) -> Builder {
            _size = value
            return self
        }

        /// Sets the size using width and height dimensions directly.
        @discardableResult
        public func size(width: PresentationSize.Dimension, height: PresentationSize.Dimension) -> Builder {
            _size = PresentationSize(width: width, height: height)
            return self
        }

        /// Enables or disables tap-to-dismiss on the background overlay.
        @discardableResult
        public func backgroundTapDismiss(_ enabled: Bool) -> Builder {
            _backgroundTapDismissEnabled = enabled
            return self
        }

        /// Sets the transition animation duration in seconds.
        @discardableResult
        public func animationDuration(_ duration: TimeInterval) -> Builder {
            _animationDuration = duration
            return self
        }

        /// Sets the corner radius of the presented view.
        @discardableResult
        public func cornerRadius(_ radius: CGFloat) -> Builder {
            _cornerRadius = radius
            return self
        }
        
        /// Sets the presentation alignment (`.edge` or `.center`).
        @discardableResult
        public func alignment(_ value: PresentationAlignment) -> Builder {
            _alignment = value
            return self
        }

        /// Sets the spring damping ratio (`0.0...1.0`). `1.0` is critical
        /// damping; values lower than `~0.7` produce visible overshoot.
        @discardableResult
        public func springDamping(_ value: CGFloat) -> Builder {
            _springDamping = value
            return self
        }

        /// Sets the initial spring velocity. `0.0` starts from rest;
        /// values around `0.5...1.0` give the animation a "thrown" feel.
        @discardableResult
        public func springVelocity(_ value: CGFloat) -> Builder {
            _springVelocity = value
            return self
        }

        /// Sets the dimming overlay color. Default is `.black`.
        @discardableResult
        public func backgroundOverlayColor(_ value: UIColor) -> Builder {
            _backgroundOverlayColor = value
            return self
        }

        /// Sets the dimming overlay opacity (`0.0...1.0`). Default is `0.40`.
        @discardableResult
        public func backgroundOverlayOpacity(_ value: CGFloat) -> Builder {
            _backgroundOverlayOpacity = value
            return self
        }

        /// Builds and returns the final `NavigatorConfiguration`.
        public func build() -> NavigatorConfiguration {
            NavigatorConfiguration(
                direction: _direction,
                size: _size,
                cornerRadius: _cornerRadius,
                backgroundTapDismissEnabled: _backgroundTapDismissEnabled,
                animationDuration: _animationDuration,
                alignment: _alignment,
                springDamping: max(0.1, min(_springDamping, 1.0)),
                springVelocity: max(0, _springVelocity),
                backgroundOverlayColor: _backgroundOverlayColor,
                backgroundOverlayOpacity: max(0, min(_backgroundOverlayOpacity, 1.0))
            )
        }
    }
}

// MARK: - Convenience Presets

@MainActor
extension NavigatorConfiguration {

    /// A full-screen presentation sliding from the bottom.
    public static let `default` = NavigatorConfiguration.builder().build()

    /// A half-height bottom sheet — the SUINavigator equivalent of
    /// UIKit's modern modal-sheet style.
    ///
    /// Slides up from the bottom edge using ``PresentationSize/halfSheet``
    /// (full container width capped at 720 pt × 50 % height) with 16-pt
    /// rounded top corners. Tap-to-dismiss on the dimmed overlay is
    /// enabled.
    ///
    /// Use this for **compact, contextual** content: pickers, brief
    /// details, confirmations, action lists. For taller content —
    /// settings, multi-page forms, substantial UIs — prefer ``sheet``.
    ///
    /// ## Usage
    ///
    /// Declarative — flip a `Bool` binding:
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var showFilters = false
    ///
    ///     var body: some View {
    ///         Button("Filters") { showFilters = true }
    ///             .znavigator(isPresented: $showFilters,
    ///                         configuration: .bottomSheet) {
    ///                 FiltersView()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// Imperative — through a `Navigator` injected as an
    /// `@EnvironmentObject`:
    ///
    /// ```swift
    /// navigator.present(configuration: .bottomSheet) {
    ///     FiltersView()
    /// }
    /// ```
    ///
    /// ## Anatomy
    ///
    /// | Property | Value |
    /// |---|---|
    /// | Direction | `.bottom` |
    /// | Size | ``PresentationSize/halfSheet`` (full × 50 %, width ≤ 720 pt) |
    /// | Corner radius | 16 pt (rounded top corners) |
    /// | Alignment | `.center` (builder default) |
    /// | Animation duration | 0.30 s |
    /// | Spring | damping `1.0`, velocity `0.0` (snappy, no overshoot) |
    /// | Background overlay | `.black` at 40 % opacity |
    /// | Tap-to-dismiss | enabled |
    ///
    /// ## Customization
    ///
    /// Start from the preset and tweak via the builder:
    ///
    /// ```swift
    /// let bouncySheet = NavigatorConfiguration.builder()
    ///     .direction(.bottom)
    ///     .size(.halfSheet)
    ///     .cornerRadius(20)               // a bit more rounding
    ///     .springDamping(0.85)            // tiny bounce on landing
    ///     .springVelocity(0.4)
    ///     .backgroundOverlayOpacity(0.5)  // slightly heavier dim
    ///     .build()
    /// ```
    ///
    /// - SeeAlso: ``sheet`` (taller variant), ``PresentationSize/halfSheet``,
    ///   ``builder()``
    public static let bottomSheet = NavigatorConfiguration.builder()
        .direction(.bottom)
        .size(.halfSheet)
        .cornerRadius(16)
        .build()

    /// A side panel sliding in from the left.
    public static let leftPanel = NavigatorConfiguration.builder()
        .direction(.left)
        .size(.sidePanel)
        .build()

    /// A side panel sliding in from the right.
    public static let rightPanel = NavigatorConfiguration.builder()
        .direction(.right)
        .size(.sidePanel)
        .build()

    /// A notification-style banner sliding down from the top.
    public static let topBanner = NavigatorConfiguration.builder()
        .direction(.top)
        .size(width: .full, height: .fraction(0.15))
        .backgroundTapDismiss(true)
        .cornerRadius(12)
        .build()

    /// A centered card presentation that slides in from the bottom.
    public static let centerCard = NavigatorConfiguration.builder()
        .direction(.bottom)
        .size(.card)
        .alignment(.center)
        .cornerRadius(20)
        .build()
    
    /// A tall bottom sheet — wider, taller, and more "substantial" than
    /// ``bottomSheet``.
    ///
    /// Slides up from the bottom edge using ``PresentationSize/sheet``
    /// (fixed 860-pt width clamped to the container × 76 % height capped
    /// at 960 pt) with 20-pt rounded top corners. Tap-to-dismiss is
    /// enabled.
    ///
    /// Use this when the modal needs significant vertical room —
    /// **settings, multi-page forms, content viewers** — and should look
    /// natural across phones *and* large windows without ever spanning
    /// the entire window on iPad / Mac Catalyst.
    ///
    /// ## Usage
    ///
    /// Declarative — flip a `Bool` binding:
    ///
    /// ```swift
    /// struct AccountView: View {
    ///     @State private var showSettings = false
    ///
    ///     var body: some View {
    ///         Button("Settings") { showSettings = true }
    ///             .znavigator(isPresented: $showSettings,
    ///                         configuration: .sheet) {
    ///                 SettingsView()
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// Item-driven — present from a binding to an `Identifiable?`:
    ///
    /// ```swift
    /// .znavigator(item: $editingProduct, configuration: .sheet) { product in
    ///     ProductEditor(product: product)
    /// }
    /// ```
    ///
    /// Imperative — through a `Navigator`:
    ///
    /// ```swift
    /// navigator.present(configuration: .sheet) {
    ///     SettingsView()
    /// }
    /// ```
    ///
    /// ## Anatomy
    ///
    /// | Property | Value |
    /// |---|---|
    /// | Direction | `.bottom` |
    /// | Size | ``PresentationSize/sheet`` (fixed 860 × 76 %, height ≤ 960 pt) |
    /// | Corner radius | 20 pt (rounded top corners) |
    /// | Alignment | `.center` (builder default) |
    /// | Animation duration | 0.30 s |
    /// | Spring | damping `1.0`, velocity `0.0` |
    /// | Background overlay | `.black` at 40 % opacity |
    /// | Tap-to-dismiss | enabled |
    ///
    /// ## When to use which
    ///
    /// | Need | Use |
    /// |---|---|
    /// | Compact picker / detail (≤ 50 % height) | ``bottomSheet`` |
    /// | Substantial form / settings (~ 75 % height) | ``sheet`` |
    /// | Centered modal with no edge attachment | ``centerCard`` |
    /// | Full-screen takeover | ``default`` |
    ///
    /// - SeeAlso: ``bottomSheet``, ``PresentationSize/sheet``,
    ///   ``builder()``
    public static let sheet = NavigatorConfiguration.builder()
        .direction(.bottom)
        .size(.sheet)
        .cornerRadius(20)
        .build()
}
