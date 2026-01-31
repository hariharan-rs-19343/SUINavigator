//
//  MacPresentationCover.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/01/25.
//

import SwiftUI
import UIKit

/// A view modifier that presents a modal view in a macOS-style cover presentation.
/// This modifier is designed for iOS 17.0 and later, utilizing custom transitions and
/// presentation styles to mimic the macOS cover sheet behavior.
/// - Parameters:
///   - item: A binding to an optional identifiable item that triggers the presentation of the modal view when non-nil.
///   - onDismiss: An optional closure that is called when the modal view is dismissed.
///   - transitionManager: A custom transitioning delegate that manages the presentation and dismissal animations.
///   - modalConfig: Configuration settings for the modal presentation, including size and corner radius.
///   - modalContent: A closure that provides the content of the modal view, taking the identifiable item as a parameter.
@available(iOS 17.0, *)
public struct ZHPresentationCoverItem<T, V>: ViewModifier, DefaultMacPresentationConfig where T: Identifiable & Equatable, V: View {
    public var transitionManager: any PresentationTransitionProtocol = ConfigurableTransitionManager.default
    public var modalConfig: ModalPresentationConfig = .default
    public var interactionDismissEnabled: Bool = false
    
    // MARK: - Private Properties
    private var item: Binding<T?>
    private var modalContent: (T) -> V
    private var onDismiss: (() -> Void)?
    
    @State var currentViewController: UIViewController?
    @State var modalCoordinator: ModalPresentationCoordinator?
    
    public init(
        item: Binding<T?>,
        @ViewBuilder content: @escaping (T) -> V,
        onDismiss: (() -> Void)? = nil
    ) {
        self.item = item
        self.modalContent = content
        self.onDismiss = onDismiss
    }
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: item.wrappedValue) { _, newValue in
                if let newValue {
                    presentModal {
                        modalContent(newValue)
                    }
                }else {
                    dismiss()
                }
            }
    }
    
    public func present(on baseViewController: UIViewController, coordinator: ModalPresentationCoordinator) {
        let presentingView: UIViewController = coordinator
            .interactiveDismiss(interactionDismissEnabled)
            .present(style: transitionManager) {
                dismiss()
            }
        
        DispatchQueue.main.async {
            baseViewController.present(presentingView, animated: true)
            self.currentViewController = presentingView // Save references to controllers for proper dismissal
        }
    }
    
    public func setPresentationCoordinator(_ coordinator: ModalPresentationCoordinator) {
        self.modalCoordinator = coordinator
    }
    
    public func dismiss() {
        DispatchQueue.main.async {
            if let currentVC = currentViewController {
                currentVC.transitioningDelegate = transitionManager
                currentVC.dismiss(animated: true) {
                    onDismiss?()
                    currentViewController = nil
                }
            }
        }
    }
}
