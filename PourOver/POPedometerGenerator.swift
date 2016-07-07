//
//  POPedometerGenerator.swift
//  PourOver
//
//  Created by kevin on 11/7/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import Foundation
import CoreMotion

let kPedometerNumberOfSteps = "CMPedometer.numberOfSteps"
let kPedometerDistance = "CMPedometer.distance"
let kPedometerSpeed = "CMPedometer.speed"
let kPedometerFloorsAscended = "CMPedometer.floorsAscended"
let kPedometerFloorsDescended = "CMPedometer.floorsDescended"

class POPedometerGenerator: POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    lazy final var pedometer = CMPedometer()
    
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
        kPedometerNumberOfSteps : POController(name: kPedometerNumberOfSteps, min: 0, max: 5000),
        kPedometerDistance : POController(name: kPedometerDistance, min: 0, max: 5000),
        kPedometerSpeed : POController(name: kPedometerSpeed, min: 0, max: 3),
        kPedometerFloorsAscended : POController(name: kPedometerFloorsAscended, min: 0, max: 5),
        kPedometerFloorsDescended : POController(name: kPedometerFloorsDescended, min: 0, max: 5)
    ]
    
    static var requiresTimer: Bool = false
    
    func update() {
        //get current values, ask sensor for updated data, etc.
    }
    
    func beginUpdating() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startPedometerUpdatesFromDate(NSDate(), withHandler: { data, error in
                //TODO: this handles movement update, what about stopping?
                if (error == nil) {
                    if let pedometerData = data {
                        if let distance = pedometerData.distance?.doubleValue {
                            self.updateValue(distance, forControllerNamed: kPedometerDistance)
                            
                            let time = pedometerData.endDate.timeIntervalSinceDate(pedometerData.startDate)
                            let speed = distance / time
                            self.updateValue(speed, forControllerNamed: kPedometerSpeed)
                        }
                        
                        self.updateValue(pedometerData.numberOfSteps.doubleValue, forControllerNamed: kPedometerNumberOfSteps)
                        if let floorsDescended = pedometerData.floorsDescended?.doubleValue {
                            self.updateValue(floorsDescended, forControllerNamed: kPedometerFloorsDescended)
                        }
                        if let floorsAscended = pedometerData.floorsAscended?.doubleValue {
                            self.updateValue(floorsAscended, forControllerNamed: kPedometerFloorsAscended)
                        }
                    }
                }
            })
        }
    }
    
    func endUpdating() {
        pedometer.stopPedometerUpdates()
    }
    
}