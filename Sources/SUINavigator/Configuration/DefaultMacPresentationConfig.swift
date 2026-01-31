//
//  DefaultMacPresentationConfig.swift
//  MEAdmin
//
//  Created by Hariharan R S on 25/09/25.
//

import SwiftUI
import Foundation

@MainActor
public protocol DefaultMacPresentationConfig {
    associatedtype V: View
    
    var transitionManager: any PresentationTransitionProtocol { get set }
    var modalConfig: ModalPresentationConfig { get set }
    var interactionDismissEnabled: Bool { get set }
    
    func present(on viewController: UIViewController, coordinator: ModalPresentationCoordinator)
    func setPresentationCoordinator(_ coordinator: ModalPresentationCoordinator)
}

@available(iOS 17.0, *)
extension DefaultMacPresentationConfig {
    
    @MainActor func presentModal(@ViewBuilder content: @escaping () -> V) {
        let topViewController = UIWindow.topViewController()
        
        DispatchQueue.main.async {
            // Dismiss any existing presented view controller before presenting a new one
            if let presentedViewController = topViewController.presentedViewController {
                presentedViewController.dismiss(animated: true) {
                    self.presentModalContent(content: content, on: topViewController)
                }
            }else {
                self.presentModalContent(content: content, on: topViewController)
            }
        }
    }
    
    @MainActor func presentModalContent(@ViewBuilder content: @escaping () -> V, on controller: UIViewController) {
        let modalView: some View = makeModalContent(content: content)
        let hostingViewController: UIViewController = makeHostingController(content: modalView)
        let coordinator: ModalPresentationCoordinator = ModalPresentationCoordinator(hostingViewController, config: modalConfig)
        self.setPresentationCoordinator(coordinator)
        self.present(on: controller, coordinator: coordinator)
    }
    
    func makeModalContent(@ViewBuilder content: @escaping () -> V) -> some View {
        content()
            .frame(maxWidth: modalConfig.maxWidth, maxHeight: modalConfig.maxHeight)
            .clipShape(RoundedRectangle(cornerRadius: modalConfig.cornerRadius))
            .shadow(color: macPresentationCover, radius: 1.0)
            .ignoresSafeArea()
    }
    
    @MainActor func makeHostingController<V: View>(content: V) -> UIViewController {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return hostingController
    }
    
    private func setupBackgrounDismissGesture(on uiViewController: UIViewController) {
        
    }
}

@available(iOS 17.0, *)
public extension DefaultMacPresentationConfig {
    
    func setTransitionManager(_ manager: any PresentationTransitionProtocol) -> Self {
        var copy = self
        copy.transitionManager = manager
        return copy
    }
    
    func setModalConfig(_ config: ModalPresentationConfig) -> Self {
        var copy = self
        copy.modalConfig = config
        return copy
    }
    
    func interactionDismiss(_ isEnabled: Bool) -> Self {
        var copy = self
        copy.interactionDismissEnabled = isEnabled
        return copy
    }
    
    var macPresentationCover: Color {
        let lightGrayColor: UIColor = .systemGray2
        let uiColor: UIColor = UIColor.setColor(dark: UIColor(hexString: "#9E9E9E"), light: lightGrayColor)
        return Color(uiColor: uiColor)
    }
    
    var stroke: Color {
        let uiColor = UIColor.setColor(dark: UIColor(hexString: "#3B3B3B"), light: UIColor(hexString: "#F5F5F5"))
        return Color(uiColor: uiColor)
    }
}
