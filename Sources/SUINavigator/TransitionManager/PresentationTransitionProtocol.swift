//
//  PresentationTransitionDelegate.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/01/25.
//

import UIKit

public protocol PresentationTransitionProtocol: NSObjectProtocol, Equatable, UIViewControllerTransitioningDelegate {
    var dismissCompletion: (() -> Void)? { get set }
    func configure(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerAnimatedTransitioning
}
