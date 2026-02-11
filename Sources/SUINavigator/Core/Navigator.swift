//
//  Navigator.swift
//  SUINavigator
//
//  Created by Hariharan R S on 11/02/26.
//


import SwiftUI
import UIKit

/// Central navigator that presents and dismisses SwiftUI views using
/// UIKit's `UIViewController` presentation system.
///
/// Use as a `@StateObject` / `@ObservedObject` in SwiftUI and inject
/// with `.environmentObject()`.
///
/// ```swift
/// @StateObject private var navigator = Navigator()
///
/// ContentView()
///     .environmentObject(navigator)
/// ```
public final class Navigator: ObservableObject {

    // MARK: - Published State

    /// `true` while a view is being presented by this navigator.
    @Published public private(set) var isPresented: Bool = false

    // MARK: - Internal State

    /// Weak reference to the currently presented hosting controller.
    private weak var presentedHostingController: UIViewController?

    // MARK: - Present

    /// Presents a SwiftUI view using UIKit's custom modal presentation.
    ///
    /// - Parameters:
    ///   - configuration: Controls direction, size, tap-to-dismiss, etc.
    ///   - content: A `@ViewBuilder` closure returning the SwiftUI view.
    @MainActor public func present<Content: View>(
        configuration: NavigatorConfiguration = .default,
        @ViewBuilder content: () -> Content
    ) {
        guard !isPresented else { return }

        guard let presentingVC = Self.topViewController() else {
            assertionFailure("[SUINavigator] Could not find a presenting view controller.")
            return
        }

        let hostingController = NavigatorHostingController(rootView: content())
        hostingController.configure(with: configuration)

        hostingController.onDismiss = { [weak self] in
            self?.isPresented = false
            self?.presentedHostingController = nil
        }

        presentingVC.present(hostingController, animated: true) { [weak self] in
            self?.isPresented = true
        }

        presentedHostingController = hostingController
    }

    /// Presents a SwiftUI view built from an `Identifiable` item.
    ///
    /// - Parameters:
    ///   - item: The item to present. Retained for the lifetime of the presentation.
    ///   - configuration: Controls direction, size, tap-to-dismiss, etc.
    ///   - content: A closure receiving the item and returning the SwiftUI view.
    @MainActor public func present<Item: Identifiable, Content: View>(
        item: Item,
        configuration: NavigatorConfiguration = .default,
        @ViewBuilder content: (Item) -> Content
    ) {
        guard !isPresented else { return }

        guard let presentingVC = Self.topViewController() else {
            assertionFailure("[SUINavigator] Could not find a presenting view controller.")
            return
        }

        let hostingController = NavigatorHostingController(rootView: content(item))
        hostingController.configure(with: configuration)

        hostingController.onDismiss = { [weak self] in
            self?.isPresented = false
            self?.presentedHostingController = nil
        }

        presentingVC.present(hostingController, animated: true) { [weak self] in
            self?.isPresented = true
        }

        presentedHostingController = hostingController
    }

    // MARK: - Dismiss

    /// Dismisses the currently presented view.
    ///
    /// - Parameter completion: Called after dismissal finishes.
    @MainActor public func dismiss(completion: (() -> Void)? = nil) {
        guard let presented = presentedHostingController else {
            completion?()
            return
        }

        presented.dismiss(animated: true) { [weak self] in
            self?.isPresented = false
            self?.presentedHostingController = nil
            completion?()
        }
    }

    // MARK: - Top View Controller Discovery

    /// Walks the view controller hierarchy to find the top-most
    /// presented controller suitable for presenting on.
    @MainActor static func topViewController(
        from root: UIViewController? = nil
    ) -> UIViewController? {
        let root = root ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController,
           let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        return root
    }
}
