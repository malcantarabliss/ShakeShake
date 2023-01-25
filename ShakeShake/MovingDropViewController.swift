//
//  FireworksViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 11/01/2023.
//

import Foundation
import UIKit

class MovingDropViewController: UIViewController {
    private var observer: NSKeyValueObservation?

    var animator: UIDynamicAnimator!

    var collisionDrop: UICollisionBehavior!
    var push: UIPushBehavior!
    var aggregateBehavior: UIDynamicBehavior!
    var friction: UIDynamicItemBehavior!

    var drop: UIView!
    var itemList: [UIView] = []

    var itemsCount: Int { 300 }
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.animate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.animator.removeAllBehaviors()
            let snapBehavior = UISnapBehavior(item: self.drop, snapTo: self.view.center)
            snapBehavior.damping = 0.25
            self.animator.addBehavior(snapBehavior)
        }
    }

    func setupDroplets() {
        for _ in 0...itemsCount {
            let dropletView = UIView(frame: .zero)
            dropletView.backgroundColor = UIColor.randomColor()
            let randomValue = CGFloat.random(in: 8...24)
            let randomX = CGFloat.random(in: 0...2)
            let randomY = CGFloat.random(in: 0...2)
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
        drop = UIView(frame: CGRect(x: view.center.x, y: view.center.y, width: 50, height: 50))
        drop.backgroundColor = .red
        view.addSubview(drop)
        observer = drop.observe(\.center, options: [.new], changeHandler: { view, value in
            self.itemList.forEach { view in
                if view.frame.intersects(self.drop.frame) {
                    print("intersected")
                    UIView.animate(withDuration: 0.1, delay: 0) {
                        self.drop.bounds = .init(x: self.drop.bounds.origin.x,
                                                 y: self.drop.bounds.origin.y,
                                                 width: self.drop.bounds.width + self.sizeIncrement,
                                                 height: self.drop.bounds.height + self.sizeIncrement)
                    }
                    view.removeFromSuperview()
                    self.itemList.removeAll(where: { $0 == view })
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
        collisionDrop.translatesReferenceBoundsIntoBoundary = true

        friction = UIDynamicItemBehavior(items: [drop])
        friction.resistance = 0
        friction.friction = 0
        friction.elasticity = 1

        // MARK: - Speed

        push = UIPushBehavior(items: [drop], mode: .instantaneous)

        aggregateBehavior = UIDynamicBehavior()
        aggregateBehavior.addChildBehavior(collisionDrop)
        aggregateBehavior.addChildBehavior(push)
        aggregateBehavior.addChildBehavior(friction)
    }

    func animate() {
        animator.addBehavior(aggregateBehavior)
        push.setAngle(.pi / 3, magnitude: 5)
    }
//
//    func calculateNewAngle() -> CGFloat {
//        let initialAngle = push.angle
//        return initialAngle * (.pi/2) + CGFloat.random(in: .pi/4 ... .pi/4)
////        switch initialAngle {
////        case 0 ..< .pi/2:
////            return initialAngle * (.pi/2)
////        default:
////            break
////        }
//        var newAngle = CGFloat.pi
//        return newAngle
//    }
}

extension MovingDropViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        print("\(#function) - \(item)")
    }

    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
        print("\(#function) - \(item)")
    }
}

//public class MyCollectionViewCell: UICollectionViewCell {
//    static let identif = "MyCollectionViewCell"
//
//    var prepareForReuseClosure: (() -> Void)!
//
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = UIColor.randomColor()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    public override func prepareForReuse() {
//        super.prepareForReuse()
//        prepareForReuseClosure()
//    }
//}

//extension MovingDropViewController: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        itemsCount
//    }
//
//    func registerCells() {
//        collectionView.register(MyCollectionViewCell.self, forCellWithReuseIdentifier: MyCollectionViewCell.identif)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyCollectionViewCell.identif, for: indexPath) as? MyCollectionViewCell
//        else { return UICollectionViewCell() }
//        cell.prepareForReuseClosure = { self.collisionItems.removeItem(cell) }
//        collisionItems.addItem(cell)
//        return cell
//    }
//}
//
//extension MovingDropViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let randomValue = CGFloat.random(in: 8...24)
//        return .init(width: randomValue,
//                     height: randomValue)
//    }
//}
