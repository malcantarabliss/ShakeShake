//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit
class FireworksViewController2: UIViewController, UICollisionBehaviorDelegate {
    var animator: UIDynamicAnimator!

    var collision: UICollisionBehavior!
    var parentSpeed: UIDynamicItemBehavior!
    var dragForce: UIFieldBehavior!
    var gravityDrag: UIFieldBehavior!
    var grav: UIFieldBehavior!
    var push: [UIPushBehavior] = []
    var turbulence: UIFieldBehavior!
    var gravityMultiplier: CGFloat { 0.2 }
    var frictionMultiplier: CGFloat { 0.2 }
    var aggregateBehavior: UIDynamicBehavior!

    var startBoundingBoxHeight: CGFloat { view.bounds.height * 0.475 }
    var startBoundingBoxWidth: CGFloat { view.bounds.width * 0.475 }
    var endBoundingBoxHeight: CGFloat { view.bounds.height * 0.525 }
    var endBoundingBoxWidth: CGFloat { view.bounds.width * 0.525 }
    var xRange: Range<CGFloat> { startBoundingBoxWidth..<endBoundingBoxWidth }
    var yRange: Range<CGFloat> { startBoundingBoxHeight..<endBoundingBoxHeight }
    var sizeRange: Range<CGFloat> { 16..<24 }
    var fireworksQuantity: Int = 150
    var fireworksViews = [UIView]()
    var didRemovePushBehaviors = false

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
        fireworksViews.forEach(view.addSubview)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animate()
        }
    }

    func setupPushes() {
        let strided: StrideTo<CGFloat> = stride(from: 0 , to: 2 * .pi, by: .pi/32)
//        let strided: StrideTo<CGFloat> = stride(from: -.pi + .pi/4 , to: -.pi/4, by: .pi/32)
        strided.forEach { value in
            let behavior = UIPushBehavior(items: [], mode: .instantaneous)
//            behavior.setAngle(value, magnitude: 0.5 + abs(sin(value)))//CGFloat.random(in: 1...1.5))
            behavior.setAngle(.pi, magnitude: 0.5 + abs(sin(value)))//CGFloat.random(in: 1...1.5))
            push.append(behavior)
        }
    }

    func animate() {
        // MARK: - Collision

        collision = UICollisionBehavior(items: fireworksViews)
        collision.collisionMode = .boundaries
//        let path = UIBezierPath()
//        path.move(to: .init(x: 0, y: view.bounds.height * 2))
//        path.addLine(to: .zero)
//        path.move(to: .init(x: view.bounds.width, y: 0))
//        path.addLine(to: .init(x: view.bounds.width, y: view.bounds.height * 2))
//        collision.addBoundary(withIdentifier: "boundaries" as NSString, for: path)
        collision.translatesReferenceBoundsIntoBoundary = true

        // MARK: - Speed

        parentSpeed = UIDynamicItemBehavior(items: fireworksViews)
        parentSpeed.items.forEach { item in
            parentSpeed.addLinearVelocity(.init(x: CGFloat.random(in: -250 ..< 250),
                                                y: CGFloat.random(in: -5000 ..< -4000) ), for: item)
        }

        dragForce = UIFieldBehavior.dragField()
        dragForce.strength = 0.1
        fireworksViews.forEach(dragForce.addItem)
        
//        gravityDrag = UIFieldBehavior.linearGravityField(direction: .init(dx: 0, dy: 1))
        gravityDrag = UIFieldBehavior.field(evaluationBlock: { [weak self, gravityMultiplier, frictionMultiplier] field, position, velocity, _, charge, deltaTime in
            guard let self = self else { return .zero }
            let mass = 0.1
            if !self.didRemovePushBehaviors {
                self.push.forEach(self.aggregateBehavior.removeChildBehavior)
                self.didRemovePushBehaviors = true
            }
            var contraryVector = CGVector(dx: velocity.dx * -1,
                                          dy: velocity.dy * -1)
            let dx = -(velocity.dx*2) * mass
            var friction: CGFloat = 0
            if velocity.dy < 0 {
                friction = -velocity.dy * frictionMultiplier
            }
            let velocityDy: CGFloat = velocity.dy
            
            let gravity: CGFloat = 9.8 * 1
            let dy = mass * gravity
            let vector: CGVector = .init(
                dx: (-velocity.dx * mass) + contraryVector.dx*0.2,
                dy: (-velocity.dy * mass) + (contraryVector.dy*0.2) + (mass*gravity) //+ friction
            )
//            return velocity
            if self.fireworksViews.count == 1 {
                print("velocity = \(velocity)")
                print("vector = \(vector)")
                print("----------")
            }
            return vector
        })
        fireworksViews.forEach(gravityDrag.addItem)

        setupPushes()
        let maxSize = fireworksViews.sorted(by: { $0.bounds.width > $1.bounds.width }).first?.bounds.width ?? .zero
//
        grav = UIFieldBehavior.linearGravityField(direction: .init(dx: 0, dy: 5))
        fireworksViews.forEach(grav.addItem)

        aggregateBehavior = UIDynamicBehavior()
//        aggregateBehavior.addChildBehavior(collision)
//        aggregateBehavior.addChildBehavior(gravityDrag)
        aggregateBehavior.addChildBehavior(dragForce)
        aggregateBehavior.addChildBehavior(grav)
//        aggregateBehavior.addChildBehavior(parentSpeed)
        
        fireworksViews
            .forEach { view in
                self.push.randomElement()?.addItem(view)
        }

        push.forEach(aggregateBehavior.addChildBehavior)
//        aggregateBehavior.addChildBehavior(push)
        animator.addBehavior(aggregateBehavior)
//        animator.setValue(true, forKey: "debugEnabled")
    }
    
}
