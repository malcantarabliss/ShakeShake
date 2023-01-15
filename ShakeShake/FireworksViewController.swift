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

//class ConfettiUnitView: UIView {
//    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
//        .path
//    }
//    override var collisionBoundingPath: UIBezierPath {
//        .init(rect: bounds.applying(.init(scaleX: 0.1, y: 0.1)))
//    }
//}

class FireworksViewController: UIViewController, UICollisionBehaviorDelegate {
    var animator: UIDynamicAnimator!

    var collision: UICollisionBehavior!
    var parentSpeed: UIDynamicItemBehavior!
    var gravityDrag: UIFieldBehavior!
    var gravityMultiplier: CGFloat { 0.25 }
    var aggregateBehavior: UIDynamicBehavior!

    var startBoundingBoxHeight: CGFloat { view.bounds.height * 0.475 }
    var startBoundingBoxWidth: CGFloat { view.bounds.width * 0.475 }
    var endBoundingBoxHeight: CGFloat { view.bounds.height * 0.525 }
    var endBoundingBoxWidth: CGFloat { view.bounds.width * 0.525 }
    var xRange: Range<CGFloat> { startBoundingBoxWidth..<endBoundingBoxWidth }
    var yRange: Range<CGFloat> { startBoundingBoxHeight..<endBoundingBoxHeight }
    var sizeRange: Range<CGFloat> { 23..<24 }
    var fireworksQuantity: Int = 125
    var fireworksViews = [UIView]()

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        for _ in 0..<fireworksQuantity {
            let randomX = CGFloat.random(in: xRange)
            let randomY = CGFloat.random(in: yRange)
            let size = CGFloat.random(in: sizeRange)
            let view = UIView(frame: CGRect(x: randomX, y: randomY, width: size, height: size))
            view.backgroundColor = UIColor.randomColor()
            fireworksViews.append(view)
        }

        fireworksViews.forEach(view.addSubview)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animate()
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
                                                y: CGFloat.random(in: -2500 ..< -1250) ), for: item)
        }

        gravityDrag = UIFieldBehavior.field(evaluationBlock: { [weak self, gravityMultiplier] field, position, velocity, mass, charge, deltaTime in
            guard let self = self else { return .zero }
            let dx = position.x < 0 || position.x > self.view.bounds.width ? 0 : -velocity.dx * mass
            let vector: CGVector = .init(
                dx: dx,
                dy: (-velocity.dy * 0.2) + gravityMultiplier + mass
            )
            return vector
        })
        fireworksViews.forEach(gravityDrag.addItem)

        aggregateBehavior = UIDynamicBehavior()
//        aggregateBehavior.addChildBehavior(collision)
        aggregateBehavior.addChildBehavior(gravityDrag)
        aggregateBehavior.addChildBehavior(parentSpeed)
        animator.addBehavior(aggregateBehavior)
    }
    
}
