//
//  NavigatorPresentationModifier.swift
//  SUINavigator
//
//  Created by Hariharan R S on 11/02/26.
//

import Foundation
import SwiftUI

// MARK: - Binding-Based Presentation Modifier

/// Monitors a `Binding<Bool>` and presents/dismisses a SwiftUI view
/// through UIKit when the value changes.
struct NavigatorPresentationModifier<Destination: View>: ViewModifier {

    @Binding var isPresented: Bool
    let configuration: NavigatorConfiguration
    let onDismiss: (() -> Void)?
    let destination: () -> Destination

    @State private var hostingController: NavigatorHostingController<Destination>?
    @State private var presenterVC: UIViewController?

    func body(content: Content) -> some View {
        content
            .background(ViewControllerResolver(onResolve: { vc in
                presenterVC = vc
                if isPresented && hostingController == nil {
                    presentContent(from: vc)
                }
            }))
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    presentContent()
                } else {
                    dismissContent()
                }
            }
    }

    private func presentContent(from explicitPresenter: UIViewController? = nil) {
        guard let presenter = explicitPresenter ?? presenterVC else { return }

        let hc = NavigatorHostingController(rootView: destination())
        hc.configure(with: configuration)

        hc.onDismiss = { [self] in
            self.isPresented = false
            self.hostingController = nil
        }

        presenter.present(hc, animated: true)
        hostingController = hc
    }

    private func dismissContent() {
        hostingController?.dismiss(animated: true) {
            hostingController = nil
            onDismiss?()
        }
    }
}

// MARK: - Item-Based Presentation Modifier

/// Monitors a `Binding<Item?>` and presents/dismisses a SwiftUI view
/// through UIKit when the item becomes non-nil / nil.
struct NavigatorItemModifier<Item: Identifiable, Destination: View>: ViewModifier {

    @Binding var item: Item?
    let configuration: NavigatorConfiguration
    let onDismiss: (() -> Void)?
    let destination: (Item) -> Destination

    @State private var hostingController: UIViewController?
    @State private var presenterVC: UIViewController?
    @State private var presentedItemID: Item.ID?

    func body(content: Content) -> some View {
        content
            .background(ViewControllerResolver(onResolve: { vc in
                presenterVC = vc
                if item != nil && hostingController == nil {
                    presentItem(from: vc)
                }
            }))
            .onChange(of: item?.id) { _, newID in
                if let newID = newID, newID != presentedItemID {
                    dismissContent {
                        presentItem()
                    }
                } else if newID == nil {
                    dismissContent()
                }
            }
    }

    private func presentItem(from explicitPresenter: UIViewController? = nil) {
        guard let presenter = explicitPresenter ?? presenterVC,
              let currentItem = item else { return }

        let hc = NavigatorHostingController(rootView: destination(currentItem))
        hc.configure(with: configuration)

        hc.onDismiss = { [self] in
            self.item = nil
            self.hostingController = nil
            self.presentedItemID = nil
        }

        presenter.present(hc, animated: true)
        hostingController = hc
        presentedItemID = currentItem.id
    }

    private func dismissContent(completion: (() -> Void)? = nil) {
        guard let hc = hostingController else {
            completion?()
            return
        }
        hc.dismiss(animated: true) {
            hostingController = nil
            presentedItemID = nil
            onDismiss?()
            completion?()
        }
    }
}

// MARK: - UIViewController Resolver

/// A zero-size `UIViewControllerRepresentable` used purely to obtain
/// a reference to the presenting `UIViewController` from SwiftUI.
private struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        vc.view.frame = .zero
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let parent = uiViewController.parent {
                onResolve(parent)
            }
        }
    }
}

// MARK: - View Extensions

public extension View {

    /// Presents a SwiftUI view using UIKit's custom modal presentation
    /// when `isPresented` becomes `true`.
    ///
    /// ```swift
    /// .znavigator(isPresented: $showDetail, configuration: .bottomSheet) {
    ///     DetailView()
    /// }
    /// ```
    func znavigator<Destination: View>(
        isPresented: Binding<Bool>,
        configuration: NavigatorConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        modifier(
            NavigatorPresentationModifier(
                isPresented: isPresented,
                configuration: configuration,
                onDismiss: onDismiss,
                destination: destination
            )
        )
    }

    /// Presents a SwiftUI view using UIKit's custom modal presentation
    /// driven by an optional `Identifiable` item.
    ///
    /// When `item` becomes non-nil the destination is presented;
    /// when set back to `nil` it is dismissed. If a new item replaces
    /// the current one, the old presentation is dismissed first.
    ///
    /// ```swift
    /// struct Product: Identifiable {
    ///     let id: Int
    ///     let name: String
    /// }
    ///
    /// @State private var selectedProduct: Product?
    ///
    /// .znavigator(item: $selectedProduct, configuration: .centerCard) { product in
    ///     ProductDetailView(product: product)
    /// }
    /// ```
    func znavigator<Item: Identifiable, Destination: View>(
        item: Binding<Item?>,
        configuration: NavigatorConfiguration = .default,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        modifier(
            NavigatorItemModifier(
                item: item,
                configuration: configuration,
                onDismiss: onDismiss,
                destination: destination
            )
        )
    }
}
