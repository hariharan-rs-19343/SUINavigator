//
//  PresentModelContentView.swift
//  ZhareHub
//
//  Created by Hariharan R S on 25/09/25.
//

import SwiftUI

/// A class to present SwiftUI content modally on a UIViewController with custom presentation styles.
/// This class wraps the SwiftUI view in a UIHostingController and manages its presentation using a
/// custom presentation controller. It also provides functionality to add a close button and animate the background color of the presented view.
/// - Parameters:
///  - hostingViewController: The UIHostingController that wraps the SwiftUI view to be presented.
/// - Note: This class requires iOS 17.0 or later.
public class ModalPresentationCoordinator: NSObject, UIGestureRecognizerDelegate {
    private var hostingController: UIViewController
    private let modalConfig: ModalPresentationConfig
    private var onDismiss: (() -> Void)?
    private var isUserInteractionEnabled: Bool = false
    
    init(_ hostingViewController: UIViewController, config modalConfig: ModalPresentationConfig) {
        self.hostingController = hostingViewController
        self.modalConfig = modalConfig
    }
    
    func present(style transition: any PresentationTransitionProtocol, dismiss onDismiss: (() -> Void)? = nil) -> UIViewController {
        
        self.onDismiss = onDismiss // Store the dismiss handler
        
        // Create a custom presentation controller
        let viewController: SUINavigator = makePresentationController(for: hostingController)
        viewController.transitioningDelegate = transition
        viewController.dismissHandler = {
            self.onDismiss?()
        }
        
        hostingController.view.frame = viewController.view.frame
        hostingController.didMove(toParent: viewController)
        
        if isUserInteractionEnabled {
            setupBackgroundGestureToDismiss()
        }
        
        return viewController
    }
    
    public func animateViewBackgroundColor() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            UIView.animate(withDuration: 0.2) {
//                self.hostingController.view.backgroundColor = UIColor.black.withAlphaComponent(0.05)
//            }
//        }
    }
    
    public func dismissBackgroundAnimate(completion: @escaping (Bool) -> Void) {
        completion(true)
//        UIView.animate(withDuration: 0.2) { [weak self] in
//            guard let self else { return completion(false) }
//            guard let hostingController = hostingController.view.subviews.first
//            else {
//                return completion(false)
//            }
//                
//            UIView.animate(withDuration: 0.2, animations: {
//                hostingController.backgroundColor = UIColor.clear
//            }, completion: completion)
//        }
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func interactiveDismiss(_ isEnable: Bool) -> Self {
        var copy = self
        copy.isUserInteractionEnabled = isEnable
        return self
    }
    
    @objc func dismissOnBackgroundTap(_ gesture: UITapGestureRecognizer) {
        // Determine which views to test — either the hosting view itself or its children
        let targetViews = hostingController.children.isEmpty
            ? [hostingController.view].compactMap { $0 }
            : hostingController.children.map { $0.view }
        
        for view in targetViews {
            guard let view else { continue }
            
            // Calculate modal frame for this view
            let modalRect = makeModalRect(for: view)
            
            // Location of the tap inside this view
            let touchLocation = gesture.location(in: view)
            
            // // Tap was outside all modal views → dismiss
            if !modalRect.contains(touchLocation) {
                onDismiss?()
                return
            }
        }
    }
}

@available(iOS 17.0, *)
private extension ModalPresentationCoordinator {
    
    private func makePresentationController(for presentedViewController: UIViewController?) -> SUINavigator {
        guard let presentedViewController else {
            fatalError("Presented View Controller is nil")
        }
        let viewController = SUINavigator()
        viewController.addChild(presentedViewController)
        viewController.view.addSubview(presentedViewController.view)
        viewController.modalPresentationStyle = .custom
        return viewController
    }
    
    private func setupBackgroundGestureToDismiss() {
        let uiTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissOnBackgroundTap))
        uiTapGesture.delegate = self
        self.hostingController.view.addGestureRecognizer(uiTapGesture)
    }
    
    private func getChildViewCGPoint(in uiView: UIView) -> CGPoint {
        let hostingView = uiView
        let hostingBounds = hostingView.bounds
        return CGPoint(x: hostingBounds.midX, y: hostingBounds.midY)
    }
    
    private func makeModalRect(for view: UIView) -> CGRect {
        let center = getChildViewCGPoint(in: view)
        return CGRect(
            x: center.x - modalConfig.maxWidth / 2,
            y: center.y - modalConfig.maxHeight / 2,
            width: modalConfig.maxWidth,
            height: modalConfig.maxHeight
        )
    }
}
