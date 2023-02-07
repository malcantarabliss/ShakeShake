//
//  MovingDropViewController+AnimatedTransitioning.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 07/02/2023.
//

import Foundation
import UIKit

extension MovingDropViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MovingDropTransitionAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        nil
    }
}

class MovingDropTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let fromVC = (transitionContext.viewController(forKey: .from) as! UINavigationController).topViewController! as! MovingDropViewController
        let toVC = transitionContext.viewController(forKey: .to)! as! FakeSuccessViewController
        let fromView = fromVC.view!
        let fireworksContainerView = fromVC.fireworksContainerView
        let toView = toVC.view!
        container.addSubview(toView)
        container.addSubview(fromView)

        let duration = transitionDuration(using: transitionContext)
        let animations = {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: duration) {
                fromView.frame.origin.y += fromView.frame.height
                fireworksContainerView.alpha = 0
            }
        }
        UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext),
                                delay: 0,
                                options: .calculationModeCubic,
                                animations: animations,
                                completion: { finished in
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
