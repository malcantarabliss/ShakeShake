//
//  FakeSuccessViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 07/02/2023.
//

import UIKit

class FakeSuccessViewController: UIViewController {

    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        transitioningDelegate = self
        // Do any additional setup after loading the view.

        view.addSubview(label)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        label.text = "Success"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FakeSuccessViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        MovingDropTransitionAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        nil
    }
}

//class MovingDropTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
//    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
//        1
//    }
//
//    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
//        let container = transitionContext.containerView
//        let fromView = transitionContext.viewController(forKey: .from)!.view!
//        let toView = transitionContext.viewController(forKey: .to)!.view!
//
//        let animations = {
//            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
//                fromView.alpha = 0
//                toView.alpha = 1
//            }
//        }
//        UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext),
//                                delay: 0,
//                                options: .calculationModeCubic,
//                                animations: animations,
//                                completion: { finished in
//            fromView.alpha = 1
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//        })
//    }
//}
