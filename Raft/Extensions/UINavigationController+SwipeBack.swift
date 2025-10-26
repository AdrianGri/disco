//
//  UINavigationController+SwipeBack.swift
//  Raft
//
//  Created by GitHub Copilot
//  Extension to enable swipe-back gesture with custom back buttons
//

import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow swipe back if there's more than one view controller in the stack
        // and no modal is being presented (prevents freezing issues)
        return viewControllers.count > 1 && presentedViewController == nil
    }

    // Ensures the swipe back gesture works even with ScrollViews or other gesture recognizers
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
