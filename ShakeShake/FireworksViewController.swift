//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit

extension UIColor {
    class func randomColor(randomAlpha: Bool = false) -> UIColor {
        let redValue = CGFloat(arc4random_uniform(255)) / 255.0;
        let greenValue = CGFloat(arc4random_uniform(255)) / 255.0;
        let blueValue = CGFloat(arc4random_uniform(255)) / 255.0;
        let alphaValue = randomAlpha ? CGFloat(arc4random_uniform(255)) / 255.0 : 1;

        return UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: alphaValue)
    }
}

class FireworksViewController: UIViewController, UICollisionBehaviorDelegate {
    var animator: UIDynamicAnimator!

    var parentSpeed: UIDynamicItemBehavior!
    var gravityDrag: UIFieldBehavior!
    var push: [UIPushBehavior] = []
    var gravityMultiplier: CGFloat { 1 }

    var startBoundingBoxHeight: CGFloat { view.bounds.height * 0.475 }
    var startBoundingBoxWidth: CGFloat { view.bounds.width * 0.475 }
    var endBoundingBoxHeight: CGFloat { view.bounds.height * 0.525 }
    var endBoundingBoxWidth: CGFloat { view.bounds.width * 0.525 }
    var xRange: Range<CGFloat> { startBoundingBoxWidth..<endBoundingBoxWidth }
    var yRange: Range<CGFloat> { startBoundingBoxHeight..<endBoundingBoxHeight }
    var sizeRange: Range<CGFloat> { 12..<32 }
    var fireworksQuantity: Int = 200
    var fireworksViews = [UIView]()
    var didRemovePushBehaviors = false

    var containerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        setupPushes()
        for _ in 0..<fireworksQuantity {
            let randomX = CGFloat.random(in: xRange)
            let randomY = CGFloat.random(in: yRange)
            let size = CGFloat.random(in: sizeRange)
            let view = UIView(frame: CGRect(x: randomX, y: randomY, width: size, height: size))
            view.backgroundColor = UIColor.randomColor()
            fireworksViews.append(view)
        }
        
        view.backgroundColor = .white
        fireworksViews.forEach(containerView.addSubview)

        view.addSubview(containerView)
//        containerView.frame = view.frame
        containerView.translatesAutoresizingMaskIntoConstraints = false
        topAnchorConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor)
        bottomAnchorConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        leadingAnchorConstraint = containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        trailingAnchorConstraint = containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([
            topAnchorConstraint,
            bottomAnchorConstraint,
            leadingAnchorConstraint,
            trailingAnchorConstraint
        ])

    }
    

    var topAnchorConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!
    var trailingAnchorConstraint: NSLayoutConstraint!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fireworksViews.sorted(by: { $0.bounds.width > $1.bounds.width })
            .forEach { view.sendSubviewToBack($0)}
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animate()
        }
    
        func updateConsts() {
            NSLayoutConstraint.deactivate([
                topAnchorConstraint,
                bottomAnchorConstraint,
                leadingAnchorConstraint,
                trailingAnchorConstraint
            ])

            containerView.translatesAutoresizingMaskIntoConstraints = true
            containerView.removeConstraints(containerView.constraints)
//            topAnchorConstraint.constant = 100
//            bottomAnchorConstraint.constant = 100
        }

        UIView.animate(withDuration: 1, delay: 2) {
            self.containerView.frame.origin.y += self.view.frame.height * 2
        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.navigationController?.pushViewController(MovingDropViewController(), animated: true)
//        }
    }

    func setupPushes() {
        let strided: StrideTo<CGFloat> = stride(from: -.pi + .pi/4 , to: -.pi/4, by: .pi/32)
        strided.forEach { value in
            let behavior = UIPushBehavior(items: [], mode: .instantaneous)
            let magnitudeVal = CGFloat.random(in: 0.5 ... 1.5)
            let offset = 1 + abs(sin(value))
            behavior.setAngle(value, magnitude: magnitudeVal * offset)
            push.append(behavior)
        }
    }

    func animate() {
        // MARK: - Speed

        parentSpeed = UIDynamicItemBehavior(items: fireworksViews)
        parentSpeed.items.forEach { item in
            let randomXLower = CGFloat.random(in: -2000 ... -1500)
            let randomXUpper = CGFloat.random(in: 1500 ... 2000)

            let randomYLower = CGFloat.random(in: -5000 ... -2500)
            let randomYUpper = CGFloat.random(in: 2500 ... 5000)
            parentSpeed.addLinearVelocity(.init(x: CGFloat.random(in: randomXLower ..< randomXUpper),
                                                y: CGFloat.random(in: randomYLower ..< randomYUpper)), for: item)
            parentSpeed.addAngularVelocity(CGFloat.random(in: -10...10), for: item)
        }

        // MARK: - Push (if needed)
//        setupPushes()
//        fireworksViews
//            .forEach { view in
//                self.push.randomElement()?.addItem(view)
//        }
//

        gravityDrag = UIFieldBehavior.field(evaluationBlock: { [weak self, gravityMultiplier] field, position, velocity, mass, charge, deltaTime in
            guard let self = self else { return .zero }
//            let mass = 0.1
            if !self.didRemovePushBehaviors {
//                self.push.forEach(self.animator.removeBehavior)
                self.animator.removeBehavior(self.parentSpeed)
                self.didRemovePushBehaviors = true
            }
            let contraryVector = CGVector(dx: velocity.dx * -1,
                                          dy: velocity.dy * -1)
            let gravity: CGFloat = 9.8 * gravityMultiplier
            let vector: CGVector = .init(
                dx: velocity.dx + contraryVector.dx*1.5,
                dy: velocity.dy + (contraryVector.dy*1.5) //+ ((mass*1.5)*gravity)
            )
            return vector
        })
        fireworksViews.forEach(gravityDrag.addItem)

        animator.addBehavior(gravityDrag)
        animator.addBehavior(parentSpeed)

//        push.forEach(aggregateBehavior.addChildBehavior)
        // Cann see the forces applied, really cool
//        animator.setValue(true, forKey: "debugEnabled")
    }
    
}
