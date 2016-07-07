//
//  POCoreMotionActivityGenerator.swift
//  PourOver
//
//  Created by kevin on 1/16/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import CoreMotion

//notification:
let kPOCoreMotionActivityGeneratorActivityTypeDidChange = "kPOCoreMotionActivityGeneratorActivityTypeDidChange"

let kStationaryController = "CMMotionActivityManager.activity.stationary"
let kActivityTypeController = "CMMotionActivityManager.activity.type"

enum POActivityType : Int {
    case Unknown
    case Walking
    case Running
    case Automotive
    case Cycling //note: used for max controller value below
}

class POCoreMotionActivityGenerator: POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    lazy final var motionActivityManager = CMMotionActivityManager()
    
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
        kStationaryController : POController(name: kStationaryController, min: 0, max: 1),
        kActivityTypeController : POController(name: kActivityTypeController, min: 0, max: Double(POActivityType.Cycling.rawValue)),
    ]
    
    static var requiresTimer: Bool = false
    
    func update() {
    }
    
    func beginUpdating() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdatesToQueue(NSOperationQueue(), withHandler: { activity in
                if let a = activity {
                    switch a.confidence {
                    case .High:
                        var activityType = POActivityType.Unknown
                        if a.walking {
                            activityType = .Walking
                        }
                        else if a.running {
                            activityType = .Running
                        }
                        else if a.automotive {
                            activityType = .Automotive
                        }
                        else if a.cycling {
                            activityType = .Cycling
                        }
                        
                        self.updateValue((a.stationary) ? 1.0 : 0.0, forControllerNamed: kStationaryController)
                        self.updateValue(Double(activityType.rawValue), forControllerNamed: kActivityTypeController)
                        
                        //post notification for UI update:
                        NSNotificationCenter.defaultCenter().postNotificationName(kPOCoreMotionActivityGeneratorActivityTypeDidChange, object: nil, userInfo: ["activityType" : activityType.rawValue]);
                    case .Medium, .Low:
                        //being stationary seems to be less sensitive than moving (or moving seems to be way too sensitive), so we allow medium & low to send stationary == true
                        if a.stationary {
                            self.updateValue((a.stationary) ? 1.0 : 0.0, forControllerNamed: kStationaryController)
                        }
                    }
                }
                
            })
        }
    }
    
    func endUpdating() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.stopActivityUpdates()
        }
    }
    
}