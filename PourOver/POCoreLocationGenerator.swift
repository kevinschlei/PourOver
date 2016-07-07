//
//  POCoreLocationGenerator.swift
//  LibraryLoader
//
//  Created by kevin on 6/15/15.
//  Copyright (c) 2015 labuser. All rights reserved.
//

/*
in Info.plist:
UIRequiredDeviceCapabilities: gps
NSLocationWhenInUseUsageDescription: This piece uses location data as a control source.
</plist>

*/

import Foundation
import CoreLocation

let kMagneticHeadingController = "CLLocationManager.heading.magneticHeading"
let kTrueHeadingController = "CLLocationManager.heading.trueHeading"
let kHeadingXController = "CLLocationManager.heading.x"
let kHeadingYController = "CLLocationManager.heading.y"
let kHeadingZController = "CLLocationManager.heading.z"
let kSpeedController = "CLLocationManager.speed"

class POCoreLocationGenerator: NSObject, POControllerUpdating, CLLocationManagerDelegate {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    lazy final var locationManager: CLLocationManager? = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
        }()

    //===================================================================================
    //MARK: Initialization
    //===================================================================================
    
    override init() {
        super.init()
        
        //add any additional activity type ranges:
        POCoreLocationGenerator.controllers[kSpeedController]?.modeRanges = [
            POActivityType.Walking : (0.0, 1.0),
            POActivityType.Running : (0.0, 7.0),
            POActivityType.Cycling : (0.0, 12.0),
            POActivityType.Automotive : (0.0, 30.0)
        ]
    }
    
    deinit {
        endUpdating()
    }
    
    //===================================================================================
    //MARK: CLLocationManagerDelegate
    //===================================================================================
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            updateValue(location.speed, forControllerNamed: kSpeedController)
        }
    }
    
    //===================================================================================
    //MARK: POControllerUpdating
    //===================================================================================
    
    static var controllers: [String : POController] = [
        kMagneticHeadingController : POController(name: kMagneticHeadingController, min: 0, max: 360),
        kTrueHeadingController : POController(name: kTrueHeadingController, min: 0, max: 360),
        kHeadingXController : POController(name: kHeadingXController, min: 0, max: 360),
        kHeadingYController : POController(name: kHeadingYController, min: 0, max: 360),
        kHeadingZController : POController(name: kHeadingZController, min: 0, max: 360),
        kSpeedController : POController(name: kSpeedController, min: 0, max: 1) //in m/s, 100km/h = 27.777
    ]
    
    static var requiresTimer: Bool = true
    
    func update() {
        if let manager = locationManager {
            if let heading = manager.heading {
                updateValue(heading.magneticHeading, forControllerNamed: kMagneticHeadingController)
                updateValue(heading.trueHeading, forControllerNamed: kTrueHeadingController)
                updateValue(heading.x, forControllerNamed: kHeadingXController)
                updateValue(heading.y, forControllerNamed: kHeadingYController)
                updateValue(heading.z, forControllerNamed: kHeadingZController)
            }
        }
    }
    
    func beginUpdating() {
        if CLLocationManager.headingAvailable() {
            if let manager = locationManager {
                manager.startUpdatingHeading()
            }
        }
        if CLLocationManager.locationServicesEnabled() {
            if let manager = locationManager {
                manager.requestWhenInUseAuthorization()
                manager.startUpdatingLocation()
            }
        }
    }
    
    func endUpdating() {
        if let manager = locationManager {
            manager.stopUpdatingHeading()
            manager.stopUpdatingLocation()
        }
        locationManager = nil
    }
    
}