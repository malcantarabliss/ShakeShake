//
//  ViewController.swift
//  ShakeShake
//
//  Created by Miguel Alcântara on 10/01/2023.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    var timer: Timer?
    var fireDate: Date?
    var finishDate: Date?

    var cmManager: CMMotionManager!
    var currentAccel: Double = .zero
    var lastAccel: Double = .zero
    var acceleration: Double = .zero
    var accelThreshold: Double = 2
    var accelFriction: Double = 0.7

    var isShaking = false

    // Based on https://www.geeksforgeeks.org/how-to-detect-shake-event-in-android/
    func handleAccelerometerUpdates(data: CMAccelerometerData?, error: Error?) {
        guard let accel = data?.acceleration else { return }
        let xAccel = abs(accel.x)
        let yAccel = abs(accel.y)
        lastAccel = currentAccel
        currentAccel = sqrt(xAccel * xAccel + yAccel * yAccel)
        let delta = currentAccel - lastAccel
        acceleration = acceleration * accelFriction + abs(delta)

        if acceleration > accelThreshold {
            if !isShaking {
                fireDate = Date()
                finishDate = nil
                isShaking = true
            }
        } else {
            if isShaking {
                finishDate = Date()
                isShaking = false
                print("Lasted = \(Calendar.current.dateComponents([.nanosecond], from: fireDate!, to: finishDate!).nanosecond! / 1000000) milliseconds")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(#function)
        becomeFirstResponder()
        self.cmManager = CMMotionManager()
        cmManager.accelerometerUpdateInterval = 0.1
        cmManager.startAccelerometerUpdates(to: .main, withHandler: handleAccelerometerUpdates)
    }

//    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        super.motionBegan(motion, with: event)
//        print(#function)
//        fireDate = Date()
//        finishDate = nil
//    }
//
//    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        super.motionEnded(motion, with: event)
//        print(#function)
//        finishDate = Date()
//        print("It lasted = \(Calendar.current.dateComponents([.second], from: fireDate!, to: finishDate!).second!) seconds")
//    }
//
//    override func motionCancelled(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        // THis is getting called after 2 seconds of continuous shaking?
//        // https://developer.apple.com/documentation/uikit/uiresponder/1621087-motioncancelled - UIKit might also call this method if the shaking goes on too long. Uh oh
//        super.motionCancelled(motion, with: event)
//        print(#function)
//        finishDate = Date()
//        print("It cancelled after \(Calendar.current.dateComponents([.second], from: fireDate!, to: finishDate!).second!) seconds")
//    }
}
