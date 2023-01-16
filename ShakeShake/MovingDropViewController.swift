//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit

//class ConfettiUnitView: UIView {
//    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
//        .path
//    }
//    override var collisionBoundingPath: UIBezierPath {
//        .init(rect: bounds.applying(.init(scaleX: 0.1, y: 0.1)))
//    }
//}

class MovingDropViewController: UIViewController {
    var animator: UIDynamicAnimator!

    var collision: UICollisionBehavior!
    var push: UIPushBehavior!
    var aggregateBehavior: UIDynamicBehavior!
    var friction: UIDynamicItemBehavior!

    var drop: UIView!
    var initialSpeedVector = CGVector(dx: 15, dy: 15)

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        drop = UIView(frame: CGRect(x: view.center.x, y: view.center.y, width: 150, height: 150))
        drop.backgroundColor = .red
        view.addSubview(drop)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animate()
        }
    }

    func animate() {
        // MARK: - Collision

        collision = UICollisionBehavior(items: [drop])
        collision.collisionMode = .everything
        collision.collisionDelegate = self
        collision.translatesReferenceBoundsIntoBoundary = true

        friction = UIDynamicItemBehavior(items: [drop])
        friction.resistance = 0
        friction.friction = 0
        friction.elasticity = 1

        // MARK: - Speed

        push = UIPushBehavior(items: [drop], mode: .instantaneous)

        aggregateBehavior = UIDynamicBehavior()
        aggregateBehavior.addChildBehavior(collision)
        aggregateBehavior.addChildBehavior(push)
        aggregateBehavior.addChildBehavior(friction)
        animator.addBehavior(aggregateBehavior)
//        push.pushDirection = .init(dx: 15, dy: 15)
        push.setAngle(.pi / 3, magnitude: 100)
    }

    func calculateNewAngle() -> CGFloat {
        let initialAngle = push.angle
        return initialAngle * (.pi/2) + CGFloat.random(in: .pi/4 ... .pi/4)
//        switch initialAngle {
//        case 0 ..< .pi/2:
//            return initialAngle * (.pi/2)
//        default:
//            break
//        }
        var newAngle = CGFloat.pi
        return newAngle
    }
}

extension MovingDropViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        push.setAngle(calculateNewAngle(), magnitude: 100)
        print(#function)
    }

    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        print(#function)
    }
}
