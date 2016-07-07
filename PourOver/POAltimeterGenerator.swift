//
//  POAltimeterGenerator.swift
//  PourOver
//
//  Created by kevin on 1/30/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import CoreMotion

let kCMAltimeter = "CMAltimeter.altitude"

class POAltimeterGenerator: POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    lazy final var altimeter = CMAltimeter()
    
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
        kCMAltimeter : POController(name: kCMAltimeter, min: -8, max: 8)
    ]
    
    static var requiresTimer: Bool = false
    
    func update() {
    }
    
    func beginUpdating() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
                (altitudeData: CMAltitudeData?, error: NSError?) in
                if let relativeAltitude = altitudeData?.relativeAltitude.doubleValue {
                    self.updateValue(relativeAltitude, forControllerNamed: kCMAltimeter)
                    print(altitudeData)
                }
            }
        }
    }
    
    func endUpdating() {
        altimeter.stopRelativeAltitudeUpdates()
    }
    
}