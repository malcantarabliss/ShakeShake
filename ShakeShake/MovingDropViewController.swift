//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit

func vectorDirection(for pushDirection: CGVector) -> Direction {
    if pushDirection.dx > 0 && pushDirection.dy > 0 { // right and down
        return .rightDown
    } else if pushDirection.dx > 0 && pushDirection.dy < 0 { // right and up
        return .rightUp
    } else if pushDirection.dx < 0 && pushDirection.dy > 0 { // left and down
        return .leftDown
    } else if pushDirection.dx < 0 && pushDirection.dy < 0 { // left and up
        return .leftUp
    }
    return .unknown
}

enum Direction {
    case rightDown
    case rightUp
    case leftDown
    case leftUp
    case unknown
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
    var drop: UIView!
    var itemList: [UIView] = []
    var initialAngleDirection: CGFloat { .pi / 3 } // rightDown
    lazy var currentAngleDirection: CGFloat = initialAngleDirection
    var basePushDirection: CGVector = .zero
    var currentAngle: CGFloat = .zero
    var pushDirection: CGVector = .zero

    var itemsCount: Int { 10 }
    var sizeIncrement: CGFloat {
        (view.bounds.width - 180) / CGFloat(itemsCount)
    }

//    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        animator = UIDynamicAnimator(referenceView: view)
//        setupCollectionView()
        setupDroplets()
        setupDrop()
        setupAnimation()
        setupShakeButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.animate()
        }

//        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
//            self.finishAnimation()
//        }
    }

    func setupShakeButton() {
        shakeButton = UIButton(type: .system, primaryAction: .init(handler: { action in
            self.pushAgain(inBaseDirection: true, accel: 1.1)
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
            let randomX = CGFloat.random(in: 0.2...1.8)
            let randomY = CGFloat.random(in: 0.2...1.8)
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
        drop = UIView(frame: CGRect(x: view.center.x, y: view.center.y, width: 140, height: 140))
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
//                        self.collisionDrop.removeItem(self.drop)
                        self.collisionDrop.addItem(self.drop)
                    })
                    view.removeFromSuperview()
                    self.itemList.removeAll(where: { $0 == view })
//                    guard self.itemList.isEmpty else { return }
//                    self.finishAnimation()
                }
            }
        })
    }

//    override func observeValue(forKeyPath keyPath: String?,
//                                     of object: Any?,
//                                     change: [NSKeyValueChangeKey : Any]?,
//                                     context: UnsafeMutableRawPointer?) {
//        detectNewFrame()
//    }

//    func setupCollectionView() {
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
//        collectionView.dataSource = self
//        collectionView.delegate = self
//        view.addSubview(collectionView)
//
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//
//        registerCells()
//    }

    func setupAnimation() {
        // MARK: - Collision

        collisionDrop = UICollisionBehavior(items: [drop])
        collisionDrop.collisionMode = .boundaries
        collisionDrop.collisionDelegate = self
//        collisionDrop.translatesReferenceBoundsIntoBoundary = true
        // Need to setup boundaries manually to detect them in delegate
        collisionDrop.addBoundary(withIdentifier: NSString(string: "top"),
                                  from: view.bounds.origin,
                                  to: .init(x: view.bounds.maxX, y: 0))
        collisionDrop.addBoundary(withIdentifier: NSString(string: "left"),
                                  from: view.bounds.origin,
                                  to: .init(x: 0, y: view.bounds.maxY))
        collisionDrop.addBoundary(withIdentifier: NSString(string: "bottom"),
                                  from: .init(x: 0, y: view.bounds.maxY),
                                  to: .init(x: view.bounds.maxX, y: view.bounds.maxY))
        collisionDrop.addBoundary(withIdentifier: NSString(string: "right"),
                                  from: .init(x: view.bounds.maxX, y: 0),
                                  to: .init(x: view.bounds.maxX, y: view.bounds.maxY))

        friction = UIDynamicItemBehavior(items: [drop])
        friction.resistance = 0
        friction.friction = 0
        friction.elasticity = 1

        // MARK: - Speed

        push = UIPushBehavior(items: [drop], mode: .instantaneous)

        // MARK: - Drag

        drag = UIFieldBehavior.dragField()
        drag.addItem(drop)
        drag.strength = 0.1

        let dragFactor = 1.5
        customField = UIFieldBehavior.field(evaluationBlock: { field, position, velocity, mass, charge, deltaTime in
            let contraryVector = CGVector(dx: velocity.dx * -1, dy: velocity.dy * -1)
            let xCalc = velocity.dx + (contraryVector.dx * dragFactor)
            let yCalc = velocity.dy + (contraryVector.dy * dragFactor)
            let finalVelocity = CGVector(dx: xCalc, dy: yCalc)
            print("finalVelocity = \(finalVelocity)")
            return finalVelocity
        })
        customField.addItem(drop)

        aggregateBehavior = UIDynamicBehavior()
        aggregateBehavior.addChildBehavior(collisionDrop)
        aggregateBehavior.addChildBehavior(push)
        aggregateBehavior.addChildBehavior(friction)
//        aggregateBehavior.addChildBehavior(drag)
        aggregateBehavior.addChildBehavior(customField)
//        customField.addChildBehavior(drag)
    }

    var customField: UIFieldBehavior!

    func animate() {
        animator.addBehavior(aggregateBehavior)
        currentAngle = currentAngleDirection
        push.setAngle(currentAngleDirection, magnitude: 2)
        basePushDirection = .init(dx: push.pushDirection.dx, dy: push.pushDirection.dy)
        pushDirection = push.pushDirection
    }

    func finishAnimation() {
        print(#function)
        animator.removeAllBehaviors()
        let snapBehavior = UISnapBehavior(item: drop, snapTo: view.center)
        snapBehavior.damping = 0.25
        animator.addBehavior(snapBehavior)
    }
//
    func calculateNewAngle(collidedIn boundary: String) -> CGFloat {
        // 0 rads => right
        // .pi / 2 => down
        // .pi => left
        // 3 * .pi / 2 => up
        if boundary == "top" {
            switch vectorDirection(for: basePushDirection) {
            case .leftUp:
                currentAngle = 2 * initialAngleDirection // go leftDown
            case .rightUp:
                currentAngle = initialAngleDirection // go rightDown
            default: break
            }
        } else if boundary == "bottom" {
            switch vectorDirection(for: basePushDirection) {
            case .leftDown:
                currentAngle = .pi + initialAngleDirection // go leftUp
            case .rightDown:
                currentAngle = -initialAngleDirection // go rightUp
            default: break
            }
        } else if boundary == "left" {
            switch vectorDirection(for: basePushDirection) {
            case .leftUp:
                currentAngle = -initialAngleDirection // go rightUp
            case .leftDown:
                currentAngle = initialAngleDirection // go rightDown
            default: break
            }
        } else if boundary == "right" {
            switch vectorDirection(for: basePushDirection) {
            case .rightUp:
                currentAngle = .pi + initialAngleDirection // go leftUp
            case .rightDown:
                currentAngle = 2 * initialAngleDirection // go leftDown
            default: break
            }
        }
        return currentAngle
    }

    func pushAgain(inBaseDirection: Bool? = nil, accel: CGFloat = 1) {
        aggregateBehavior.removeChildBehavior(push)
        push = UIPushBehavior(items: [drop], mode: .instantaneous)
        aggregateBehavior.addChildBehavior(push)
        let helperPush = UIPushBehavior(items: [drop], mode: .instantaneous)
        helperPush.setAngle(currentAngle, magnitude: 1)
        if inBaseDirection == true {
//            let accelDirection = CGVector(dx: (helperPush.pushDirection.dx + helperPush.pushDirection.dx) * accel,
//                                          dy: (helperPush.pushDirection.dy + helperPush.pushDirection.dy) * accel)
            let accelDirection = CGVector(dx: helperPush.pushDirection.dx,
                                          dy: helperPush.pushDirection.dy)
//            basePushDirection = accelDirection
            print("accelDirection = \(accelDirection)")
            push.pushDirection = accelDirection
        } else {
        }
        print("direction = \(vectorDirection(for: basePushDirection))")
    }

    func getCurrentAngle() {
        
    }
}

extension MovingDropViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        print("collided with __\((identifier as? String) ?? "")__")
        let boundary = (identifier as? String) ?? ""
        let helperPush = UIPushBehavior(items: [drop], mode: .instantaneous)
        helperPush.setAngle(calculateNewAngle(collidedIn: boundary), magnitude: 2)
        let dx = helperPush.pushDirection.dx > 0 ? abs(basePushDirection.dx) : -abs(basePushDirection.dx)
        let dy = helperPush.pushDirection.dy > 0 ? abs(basePushDirection.dy) : -abs(basePushDirection.dy)
        basePushDirection = .init(dx: dx, dy: dy)
        self.pushDirection = basePushDirection
        if pushDirection.dx > 0 && pushDirection.dy > 0 { // right and down
            print("going rightDown")
        } else if pushDirection.dx > 0 && pushDirection.dy < 0 { // right and up
            print("going rightUp")
        } else if pushDirection.dx < 0 && pushDirection.dy > 0 { // left and down
            print("going leftDown")
        } else if pushDirection.dx < 0 && pushDirection.dy < 0 { // left and up
            print("going leftUp")
        }
        
        // To remove from line below
//        aggregateBehavior.removeChildBehavior(push)
//        push = UIPushBehavior(items: [drop], mode: .instantaneous)
//        aggregateBehavior.addChildBehavior(push)
//        push.pushDirection = helperPush.pushDirection
        // To remove until line above
        
//        print("collided, new direction = \(nextDirection(for: basePushDirection))")
    }

    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
//        print("\(#function) - \(item)")
    }
}
