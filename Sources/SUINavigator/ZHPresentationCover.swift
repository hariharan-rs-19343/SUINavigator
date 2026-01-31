//
//  File.swift
//  MEAdmin
//
//  Created by Hariharan R S on 26/09/25.
//

import SwiftUI
import UIKit


/// A view modifier that presents a modal view with customizable transition and configuration.
/// This modifier uses a `PresentationTransitionProtocol` to manage the transition animations and a `ModalPresentationConfig` to define the modal's appearance and behavior.
/// - Parameters:
///  - isPresented: A binding to a Boolean value that determines whether the modal is presented or not.
///  - content: A closure that returns the content of the modal view.
///  - onDismiss: An optional closure that is called when the modal is dismissed.
///  - Note: This modifier is available on iOS 17.0 and later.
@available(iOS 17.0, *)
public struct ZHPresentationCover<V>: ViewModifier, DefaultMacPresentationConfig where V: View {
    
    public var transitionManager: any PresentationTransitionProtocol = ConfigurableTransitionManager.default
    public var modalConfig: ModalPresentationConfig = .default
    public var interactionDismissEnabled: Bool = false
    
    // MARK: - Private Properties
    private var isPresented: Binding<Bool>
    private var modalView: () -> V
    private var onDismiss: (() -> Void)?
    
    @State private var currentViewController: UIViewController?
    @State private var modalCoordinator: ModalPresentationCoordinator?
    
    public init(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> V,
        onDismiss: (() -> Void)? = nil
    ) {
        self.isPresented = isPresented
        self.modalView = content
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented.wrappedValue) { _, newValue in
                if newValue {
                    presentModal {
                        self.modalView()
                    }
                }else {
                    // if newValue set as nil, currently presented view should be dismiss.
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
            coordinator.animateViewBackgroundColor() // Animate the hosting view background color
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
                modalCoordinator?.dismissBackgroundAnimate(completion: { _ in
                    currentVC.dismiss(animated: true) {
                        onDismiss?()
                        isPresented.wrappedValue = false
                    }
                })
            }
        }
    }
}
