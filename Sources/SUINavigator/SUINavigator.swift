// The Swift Programming Language
// https://docs.swift.org/swift-book


import UIKit

/// A custom view controller for managing presentations on macOS via Mac Catalyst.
/// This view controller handles layout updates and dismissal actions.
internal class SUINavigator: UIViewController {
    var dismissHandler: (() -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /// Called whenever the view's subviews need to be laid out.
    ///
    /// This method ensures that the presented view remains properly positioned
    /// and resized according to the window dimensions.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        DispatchQueue.main.async {
            self.updateLayout()
        }
    }
    
    /// Updates the layout of the presented view.
    ///
    /// This method ensures that the view re-renders correctly when the window size changes.
    private func updateLayout() {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    @objc func dismissViewOnTap() {
        self.dismissHandler?()
    }
}
