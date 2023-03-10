//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit

enum DropDirection {
    case up
    case down
    case left
    case right
    case rightDown
    case rightUp
    case leftDown
    case leftUp
    case none
    case unknown

    init(with direction: CGVector) {
        self = Self.vectorDirection(for: direction)
    }

    init(for angle: CGFloat) {
        if angle == 0 || angle == .pi*2 {
            self = .right
        } else if angle > 0 && angle < .pi/2{
            self = .rightDown
        } else if angle == .pi/2 {
            self = .down
        } else if angle > .pi/2 && angle < .pi {
            self = .leftDown
        } else if angle == .pi {
            self = .left
        } else if angle > .pi && angle < .pi*1.5 {
            self = .leftUp
        } else if angle == .pi*1.5 {
            self = .up
        } else if angle > .pi*1.5 && angle < .pi*2 {
            self = .rightUp
        } else {
            self = .none
        }
    }

    func getAngle(with initialAngle: CGFloat) -> CGFloat {
        switch self {
        case .up:
            return -.pi / 2
        case .down:
            return .pi / 2
        case .left:
            return .pi
        case .right:
            return 0
        case .rightDown:
            return initialAngle
        case .rightUp:
            return -initialAngle
        case .leftDown:
            return .pi - initialAngle
        case .leftUp:
            return .pi + initialAngle
        case .none:
            return 0
        case .unknown:
            return .leastNormalMagnitude
        }
    }

    static func vectorDirection(for pushDirection: CGVector) -> DropDirection {
        if pushDirection.dx > 0 && pushDirection.dy > 0 {
            return .rightDown
        } else if pushDirection.dx > 0 && pushDirection.dy < 0 {
            return .rightUp
        } else if pushDirection.dx < 0 && pushDirection.dy > 0 {
            return .leftDown
        } else if pushDirection.dx < 0 && pushDirection.dy < 0 {
            return .leftUp
        } else if pushDirection.dx == 0 && pushDirection.dy < 0 {
            return .up
        } else if pushDirection.dx == 0 && pushDirection.dy > 0 {
            return .down
        } else if pushDirection.dx < 0 && pushDirection.dy == 0 {
            return .left
        } else if pushDirection.dx > 0 && pushDirection.dy == 0 {
            return .right
        } else if pushDirection.dx == 0 && pushDirection.dy == 0 {
            return .none
        }
        return .unknown
    }
}

enum Boundary: String {
    case top
    case bottom
    case left
    case right
    case unknown

    init(nsCopying: NSCopying?) {
        guard let strValue = nsCopying as? String else {
            self = .unknown
            return
        }
        self = .init(rawValue: strValue) ?? .unknown
    }
}

class BigDrop: UIView {
    override var collisionBoundingPath: UIBezierPath {
        .init(rect: self.bounds)
    }

    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        .rectangle
    }
}

class MovingDropViewController: UIViewController {
    private var observer: NSKeyValueObservation?

    var animator: UIDynamicAnimator!

    var collisionDrop: UICollisionBehavior!
    var push: UIPushBehavior!
    var aggregateBehavior: UIDynamicBehavior!
    var friction: UIDynamicItemBehavior!
    var drag: UIFieldBehavior!

    var shakeButton = UIButton()
    var drop: BigDrop!
    var itemList: [UIView] = []

    var initialAngle: CGFloat { .pi / 3 }
    var initialDirection: DropDirection = .unknown

    var currentPushDirection: CGVector = .zero
    var currentDirection: DropDirection = .unknown
    var currentAngle: CGFloat {
        currentDirection.getAngle(with: initialAngle)
    }

    var initialSize: CGFloat { 120 }
    var itemsCount: Int { 100 }
    var dragFactor: CGFloat { 0.5 }
    var endPadding: CGFloat { 40 }
    var endSize: CGFloat? { 280 }
    var currentMass: CGFloat { drop.bounds.height / initialSize }
    lazy var sizeIncrement: CGFloat = ((endSize ?? view.bounds.width) - drop.bounds.width - endPadding*2) / CGFloat(itemsCount)

    // MARK: - End Animation
    var parentSpeed: UIDynamicItemBehavior!
    var gravityDrag: UIFieldBehavior!
    var pushList: [UIPushBehavior] = []
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
    var topAnchorConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!
    var trailingAnchorConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
        setupDroplets()
        setupDrop()
        setupAnimation()
        setupShakeButton()
        view.backgroundColor = .white
        randomizeAngle()
        transitioningDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.animate()
        }
    }

    func updateBoundaries() {
        let side = max(0, (drop.bounds.width / 2) - (initialSize / 2))
        let vertical = max(0, (drop.bounds.height / 2) - (initialSize / 2))
        func doUpdate() {
            collisionDrop.removeAllBoundaries()
            collisionDrop.addBoundary(withIdentifier: NSString(string: Boundary.top.rawValue),
                                      from: .init(x: 0 + side, y: 0 + vertical),
                                      to: .init(x: view.bounds.maxX - side, y: 0 + vertical))
            collisionDrop.addBoundary(withIdentifier: NSString(string: Boundary.left.rawValue),
                                      from: .init(x: 0 + side, y: 0 + vertical),
                                      to: .init(x: 0 + side, y: view.bounds.maxY - vertical))
            collisionDrop.addBoundary(withIdentifier: NSString(string: Boundary.bottom.rawValue),
                                      from: .init(x: 0 + side, y: view.bounds.maxY - vertical),
                                      to: .init(x: view.bounds.maxX - side, y: view.bounds.maxY - vertical))
            collisionDrop.addBoundary(withIdentifier: NSString(string: Boundary.right.rawValue),
                                      from: .init(x: view.bounds.maxX - side, y: 0 + vertical),
                                      to: .init(x: view.bounds.maxX - side, y: view.bounds.maxY - vertical))
        }
        DispatchQueue.main.async {
            doUpdate()
        }
    }

    func animate() {
        push.setAngle(initialDirection.getAngle(with: initialAngle), magnitude: 5)
        currentPushDirection = .init(dx: push.pushDirection.dx, dy: push.pushDirection.dy)
        pushAgain()
    }

    func finishAnimation() {
        animator.removeAllBehaviors()
        let snapBehavior = UISnapBehavior(item: drop, snapTo: view.center)
        snapBehavior.damping = 0.5
        animator.addBehavior(snapBehavior)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            let vc = FireworksViewController()
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true)
            self.beginEndAnimation()
        }
    }

    func randomizeAngle() {
        let list: [DropDirection] = [
            .rightDown,
            .leftDown,
            .rightUp,
            .leftUp
        ]
        initialDirection = list.randomElement() ?? .rightUp
        let randomized = currentAngle
        print("""
        ------
        radians = \(randomized)
        degress = \(randomized * (180/CGFloat.pi))
        ------
        """)
    }

    func pushAgain() {
        animator.removeBehavior(push)
        push = UIPushBehavior(items: [drop], mode: .instantaneous)
        animator.addBehavior(push)

        currentDirection = DropDirection(with: currentPushDirection)
        let helperPush = UIPushBehavior(items: [drop], mode: .instantaneous)
        helperPush.setAngle(currentAngle, magnitude: 5)
        currentPushDirection = helperPush.pushDirection
        push.pushDirection = helperPush.pushDirection
    }
}

extension MovingDropViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        print("collided with __\(Boundary(nsCopying: identifier))__")
    }

    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        print("\(#function) - \(item)")
    }
}

extension MovingDropViewController {
    func setupShakeButton() {
        shakeButton = UIButton(type: .system, primaryAction: .init(handler: { action in
            self.pushAgain()
        }))
        shakeButton.setTitle("SHAKE", for: .normal)
        view.addSubview(shakeButton)
        shakeButton.translatesAutoresizingMaskIntoConstraints = false
        shakeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        shakeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        shakeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        shakeButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        shakeButton.backgroundColor = .darkGray.withAlphaComponent(0.5)
    }

    func setupDroplets() {
        for _ in 0..<itemsCount {
            let dropletView = UIView(frame: .zero)
            dropletView.backgroundColor = UIColor.randomColor()
            let randomValue = CGFloat.random(in: 8...24)
            let randomX = CGFloat.random(in: 0.5...1.5)
            let randomY = CGFloat.random(in: 0.5...1.5)
            view.addSubview(dropletView)
            dropletView.translatesAutoresizingMaskIntoConstraints = false
            dropletView.heightAnchor.constraint(equalToConstant: randomValue).isActive = true
            dropletView.widthAnchor.constraint(equalTo: dropletView.heightAnchor).isActive = true
            NSLayoutConstraint(item: dropletView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: randomX, constant: 0).isActive = true
            NSLayoutConstraint(item: dropletView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: randomY, constant: 0).isActive = true
            itemList.append(dropletView)
        }
    }

    func setupDrop() {
        drop = BigDrop(frame: CGRect(x: view.center.x, y: view.center.y, width: initialSize, height: initialSize))
        drop.backgroundColor = .red
        view.addSubview(drop)
        observer = drop.observe(\.center, options: [.new], changeHandler: { view, value in
            self.itemList.forEach { view in
                if view.frame.intersects(self.drop.frame) {
                    UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState], animations: {
                        self.drop.bounds = .init(x: self.drop.bounds.origin.x,
                                                 y: self.drop.bounds.origin.y,
                                                 width: self.drop.bounds.width + self.sizeIncrement,
                                                 height: self.drop.bounds.height + self.sizeIncrement)
                    }, completion: { _ in
                        self.updateBoundaries()
                    })
                    view.removeFromSuperview()
                    self.itemList.removeAll(where: { $0 == view })
                    guard self.itemList.isEmpty else { return }
                    self.finishAnimation()
                }
            }
        })
    }

    func setupCollision() {
        collisionDrop = UICollisionBehavior(items: [drop])
        collisionDrop.collisionMode = .everything
        collisionDrop.collisionDelegate = self
//        collisionDrop.translatesReferenceBoundsIntoBoundary = true
        // Need to setup boundaries manually to detect them in delegate
        updateBoundaries()
    }

    func setupFriction() {
        friction = UIDynamicItemBehavior(items: [drop])
        friction.resistance = 0
        friction.friction = 0
        friction.elasticity = 1
    }

    func setupPush() {
        push = UIPushBehavior(items: [drop], mode: .instantaneous)
    }

    func setupDrag() {
        let dragFactor = self.dragFactor
        drag = UIFieldBehavior.field(evaluationBlock: { field, position, velocity, mass, charge, deltaTime in
            let offset = (self.currentMass * 2)
            let dragFactor = 1 + (dragFactor * offset)
            let contraryVector = CGVector(dx: velocity.dx * -1,
                                          dy: velocity.dy * -1)
            self.currentPushDirection = velocity
            self.currentDirection = DropDirection.vectorDirection(for: velocity)
            let xCalc = velocity.dx + (contraryVector.dx * dragFactor)
            let yCalc = velocity.dy + (contraryVector.dy * dragFactor)
            let finalVelocity = CGVector(dx: xCalc, dy: yCalc)
            return finalVelocity
        })
        drag.addItem(drop)
    }

    func setupAnimation() {
        // MARK: - Collision

        setupCollision()

        // MARK: - Wall friction

        setupFriction()

        // MARK: - Speed

        setupPush()

        // MARK: - Drag

        setupDrag()

        animator.addBehavior(collisionDrop)
        animator.addBehavior(push)
        animator.addBehavior(friction)
        animator.addBehavior(drag)
    }

}

extension MovingDropViewController {
    func animateEndDismiss() {
        func updateConsts() {
            NSLayoutConstraint.deactivate([
                topAnchorConstraint,
                bottomAnchorConstraint,
                leadingAnchorConstraint,
                trailingAnchorConstraint
            ])

            containerView.translatesAutoresizingMaskIntoConstraints = true
            containerView.removeConstraints(containerView.constraints)
//            topAnchorConstraint.constant = 1000
//            bottomAnchorConstraint.constant = 100
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            updateConsts()
            UIView.animate(withDuration: 1, delay: 0) {
//                self.containerView.frame.origin.y += self.view.frame.height * 2
//                self.fireworksViews.forEach { $0.alpha = 0 }
                let vc = FakeSuccessViewController()
                vc.transitioningDelegate = self
                vc.modalPresentationStyle = .custom
                self.present(vc, animated: true)
//                self.view.layoutIfNeeded()
            }
        }
    }
    func setupEndParticlesContainerView() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
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
    func setupEndParticles() {
        for _ in 0..<fireworksQuantity {
            let randomX = CGFloat.random(in: xRange)
            let randomY = CGFloat.random(in: yRange)
            let size = CGFloat.random(in: sizeRange)
            let view = UIView(frame: CGRect(x: randomX, y: randomY, width: size, height: size))
            view.backgroundColor = UIColor.randomColor()
            view.alpha = 0
            fireworksViews.append(view)
        }
        fireworksViews.forEach(containerView.addSubview)
        UIView.animate(withDuration: 0.3, delay: 0, animations: { self.fireworksViews.forEach { $0.alpha = 1 } })
    }

    func beginEndAnimation() {
        animator.removeAllBehaviors()
        setupEndParticlesContainerView()
        setupEndParticles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animateEnd()
        }
    }

    func animateEnd() {
        // MARK: - Speed

        parentSpeed = UIDynamicItemBehavior(items: fireworksViews)
        parentSpeed.items.forEach { item in
            let randomXLower = CGFloat.random(in: -2000 ... -1500)
            let randomXUpper = CGFloat.random(in: 1500 ... 2000)

            let randomYLower = CGFloat.random(in: -7500 ... -2500)
            let randomYUpper = CGFloat.random(in: 2500 ... 5000)
            parentSpeed.addLinearVelocity(.init(x: CGFloat.random(in: randomXLower ..< randomXUpper),
                                                y: CGFloat.random(in: randomYLower ..< randomYUpper)), for: item)
            parentSpeed.addAngularVelocity(CGFloat.random(in: -10...10), for: item)
        }

        // MARK: - Push (if needed)
//        setupPushes()
//        fireworksViews
//            .forEach { view in
//                self.pushList.randomElement()?.addItem(view)
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
                dy: velocity.dy + (contraryVector.dy*1.5) + (mass*gravity)
            )
            return vector
        })
        fireworksViews.forEach(gravityDrag.addItem)

        animator.addBehavior(gravityDrag)
        animator.addBehavior(parentSpeed)

        animateEndDismiss()

//        pushList.forEach(aggregateBehavior.addChildBehavior)
        // Cann see the forces applied, really cool
//        animator.setValue(true, forKey: "debugEnabled")
    }
}
