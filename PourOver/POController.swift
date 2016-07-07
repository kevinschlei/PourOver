//
//  FrameworkCoordinator.swift
//  LibraryLoader
//
//  Created by labuser on 6/15/15.
//  Copyright (c) 2015 labuser. All rights reserved.
//

import Foundation

protocol POControllerDelegate: class {
    
    //===================================================================================
    //MARK: Value Patching
    //===================================================================================
    
    /**
    The delegate implementation of this method should take the value and pass it to its final in-graph destination.
    
    Note that the controller name is a C string. If it were passed as a String, the conversion to const char* introduces a significant performance hit, especially when this method is updated at a high frequency.
    */
    func valueChanged(value: Double, controllerName: UnsafePointer<CChar>, instance: Int?)
    
}

class POController: CustomStringConvertible, Equatable {
    
    //===================================================================================
    //MARK: Values
    //===================================================================================
    
    final var name: [CChar]
    final var active: Bool
    final var sentValue: Double?
    final var minimumValue: Double
    final var maximumValue: Double
    final var modeRanges: [POActivityType : (minimumValue: Double, maximumValue: Double)] = [:]
    
    weak var delegate: POControllerDelegate?
    
    final let defaultMinimumValue: Double
    final let defaultMaximumValue: Double
    
    //===================================================================================
    //MARK: Initialization
    //===================================================================================
    
    init(name: String, min: Double, max: Double) {
        self.name = name.cStringUsingEncoding(NSUTF8StringEncoding)!
        minimumValue = min
        maximumValue = max
        active = false
        sentValue = nil
        delegate = nil
        defaultMinimumValue = minimumValue
        defaultMaximumValue = maximumValue
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POController.kPOControllerCoordinatorActivityModeDidChangeNotificationReceived(_:)), name: kPOControllerCoordinatorActivityModeDidChange, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //===================================================================================
    //MARK: Printable
    //===================================================================================
    
    var description: String {
        let n = String.fromCString(name)!
        return "POController name:\(n) active:\(active) minimumValue:\(minimumValue) maximumValue:\(maximumValue) sentValue:\(sentValue) delegate:\(delegate)"
    }
    
    //===================================================================================
    //MARK: Functionality
    //===================================================================================
    
    func patchValue(value: Double, instance: Int?) {
        if value != sentValue {
            if let controllerDelegate = delegate {
                let normalized = (value - minimumValue) / (maximumValue - minimumValue)
                let clamped = max(min(normalized, 1.0), 0.0);
                controllerDelegate.valueChanged(clamped, controllerName: name, instance: instance)
                sentValue = value
//                print("new sentValue \(sentValue) from value \(value)")
            }
        }
    }
    
    /**
     Clears the sentValue property before calling patchValue:instance: to guarantee the incoming value is passed through. Useful for triggers where the value may not need to change.
     */
    func forcePatchValue(value: Double, instance: Int?) {
        sentValue = nil;
        patchValue(value, instance: instance)
    }
    
    //===================================================================================
    //MARK: Noficications
    //===================================================================================
    
    @objc func kPOControllerCoordinatorActivityModeDidChangeNotificationReceived(notification: NSNotification) {
        if let rawValue = notification.userInfo?["activityType"]?.integerValue {
            if let type = POActivityType(rawValue: rawValue) {
                if let modeRange = modeRanges[type] {
                    minimumValue = modeRange.minimumValue
                    maximumValue = modeRange.maximumValue
                }
            }
        }
    }
    
}

func ==(lhs: POController, rhs: POController) -> Bool {
    return lhs.name == rhs.name && lhs.minimumValue == rhs.minimumValue && lhs.maximumValue == rhs.maximumValue
}

protocol POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    static var controllers: [String : POController] { get set }
    static var requiresTimer: Bool { get }
    
    //===================================================================================
    //MARK: Controller Updating
    //===================================================================================
    
    func beginUpdating()
    func endUpdating()
    
    /**
    Updates active POControllers and patches the new value to their delegate. Values matching the previously sent value are not sent. Typically called from a global update timer.
    */
    func update()
    
}

extension POControllerUpdating {
    
    func clearControllerSentValues() {        
        for controller in Array(Self.controllers.values) {
            controller.sentValue = nil
        }
    }
    
    func updateValue(value: Double, forControllerNamed controller: String, instance: Int?) {
        if let c = Self.controllers[controller] {
            if c.active {
                c.patchValue(value, instance: instance)
            }
        }
    }
    
    func forceUpdateValue(value: Double, forControllerNamed controller: String, instance: Int?) {
        if let c = Self.controllers[controller] {
            if c.active {
                c.forcePatchValue(value, instance: instance)
            }
        }
    }
    
    func updateValue(value: Double, forControllerNamed controller: String) {
        updateValue(value, forControllerNamed: controller, instance: nil)
    }
    
    func forceUpdateValue(value: Double, forControllerNamed controller: String) {
        forceUpdateValue(value, forControllerNamed: controller, instance: nil)
    }
    
    static func printControllerNames() {
        for controllerName in Self.controllerNames() {
            print(controllerName)
        }
    }
    
    static func controllerNames() -> [String] {
        return Array(Self.controllers.keys)
    }
    
}

func ==(lhs: POControllerUpdating, rhs: POControllerUpdating) -> Bool {
    return lhs.dynamicType.controllers == rhs.dynamicType.controllers
}

