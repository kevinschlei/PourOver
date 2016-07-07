//
//  POCoreMotionGenerator.swift
//  LibraryLoader
//
//  Created by kevin on 6/15/15.
//  Copyright (c) 2015 labuser. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion

//constants for controller names:
//note: case-insensitive compared for lookup
let kPitchController = "CMMotionManager.deviceMotion.attitude.pitch"
let kRollController = "CMMotionManager.deviceMotion.attitude.roll"
let kYawController = "CMMotionManager.deviceMotion.attitude.yaw"
let kGravityXController = "CMMotionManager.deviceMotion.gravity.x"
let kGravityYController = "CMMotionManager.deviceMotion.gravity.y"
let kGravityZController = "CMMotionManager.deviceMotion.gravity.z"
let kUserAccelerationXController = "CMMotionManager.deviceMotion.userAcceleration.x"
let kUserAccelerationYController = "CMMotionManager.deviceMotion.userAcceleration.y"
let kUserAccelerationZController = "CMMotionManager.deviceMotion.userAcceleration.z"
let kRotationRateXController = "CMMotionManager.deviceMotion.rotationRate.x"
let kRotationRateYController = "CMMotionManager.deviceMotion.rotationRate.y"
let kRotationRateZController = "CMMotionManager.deviceMotion.rotationRate.z"

class POCoreMotionGenerator: POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    //framework objects should be lazy loaded, not instantiated during init()
    lazy final var motionManager = CMMotionManager()
    
    //===================================================================================
    //MARK: Initialization
    //===================================================================================

    deinit {
        endUpdating()
    }
    
    //===================================================================================
    //MARK: POControllerUpdating
    //===================================================================================
    
    static var controllers: [String : POController] = [
        kPitchController : POController(name: kPitchController, min: -M_PI_2, max: M_PI_2),
        kRollController : POController(name: kRollController, min: -M_PI, max: M_PI),
        kYawController : POController(name: kYawController, min: -M_PI, max: M_PI),
        kGravityXController : POController(name: kGravityXController, min: -M_PI, max: M_PI),
        kGravityYController : POController(name: kGravityYController, min: -M_PI, max: M_PI),
        kGravityZController : POController(name: kGravityZController, min: -M_PI, max: M_PI),
        kUserAccelerationXController : POController(name: kUserAccelerationXController, min: -M_PI, max: M_PI),
        kUserAccelerationYController : POController(name: kUserAccelerationYController, min: -M_PI, max: M_PI),
        kUserAccelerationZController : POController(name: kUserAccelerationZController, min: -M_PI, max: M_PI),
        kRotationRateXController : POController(name: kRotationRateXController, min: -M_PI, max: M_PI),
        kRotationRateYController : POController(name: kRotationRateYController, min: -M_PI, max: M_PI),
        kRotationRateZController : POController(name: kRotationRateZController, min: -M_PI, max: M_PI),
    ]
    
    static var requiresTimer: Bool = true
    
    func update() {
        if let deviceMotion = motionManager.deviceMotion {
            updateValue(deviceMotion.attitude.pitch, forControllerNamed: kPitchController)
            updateValue(deviceMotion.attitude.roll, forControllerNamed: kRollController)
            updateValue(deviceMotion.attitude.yaw, forControllerNamed: kYawController)
            
            updateValue(deviceMotion.gravity.x, forControllerNamed: kGravityXController)
            updateValue(deviceMotion.gravity.y, forControllerNamed: kGravityYController)
            updateValue(deviceMotion.gravity.z, forControllerNamed: kGravityZController)
            
            updateValue(deviceMotion.userAcceleration.x, forControllerNamed: kUserAccelerationXController)
            updateValue(deviceMotion.userAcceleration.y, forControllerNamed: kUserAccelerationYController)
            updateValue(deviceMotion.userAcceleration.z, forControllerNamed: kUserAccelerationZController)
            
            updateValue(deviceMotion.rotationRate.x, forControllerNamed: kRotationRateXController)
            updateValue(deviceMotion.rotationRate.y, forControllerNamed: kRotationRateYController)
            updateValue(deviceMotion.rotationRate.z, forControllerNamed: kRotationRateZController)
        }
    }
    
    func beginUpdating() {
        if motionManager.gyroAvailable {
            motionManager.startDeviceMotionUpdates()
        }
    }
    
    func endUpdating() {
        motionManager.stopDeviceMotionUpdates()
    }
    
}
