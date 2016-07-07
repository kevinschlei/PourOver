//
//  POControllerMaster.swift
//  PourOver
//
//  Created by kevin on 6/17/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import Foundation

let kPOControllerCoordinatorActivityModeDidChange = "kPOControllerCoordinatorActivityModeDidChange"

let kFreezeControllers = "kFreezeControllers"
let kThawControllers = "kThawControllers"

class POControllerCoordinator: NSObject  {
    
    //===================================================================================
    //MARK: Public Properties
    //===================================================================================
    
    weak final var controllerDelegate: POControllerDelegate!
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    /**
    Internally instantiated generator types.
    */
    private var generatorTypes: [POControllerUpdating.Type] = [
        POCoreMotionGenerator.self,
        POPedometerGenerator.self,
        POCoreLocationGenerator.self,
        POCameraGenerator.self,
        POCoreMotionActivityGenerator.self,
        POAltimeterGenerator.self
    ]
    
    private var activeGenerators: [POControllerUpdating] = []
    private var timedGenerators: [POControllerUpdating] = []
    private var customGenerators: [POControllerUpdating] = []
    
    private var frozen: Bool = false
    
    /**
    A readonly list of controller names usable in Pd patches by [psr] objects. For example: CMDeviceMotion.deviceMotion.gravity.x
    */
    var receivableControllersList: [String] {
        get {
            //printing:
            var build: [String] = []
            for generatorType in generatorTypes {
                build.appendContentsOf(generatorType.controllerNames())
            }
            return build.sort {
                return $0 < $1
            }
        }
    }
    
    var updateTimer: NSTimer?
    
    static let activityTypes: [POActivityType] = [
        POActivityType.Walking,
        POActivityType.Running,
        POActivityType.Cycling,
        POActivityType.Automotive
    ]
    
    var activityType: POActivityType? {
        didSet {
            if let type = activityType {
                NSNotificationCenter.defaultCenter().postNotificationName(kPOControllerCoordinatorActivityModeDidChange, object: nil, userInfo: ["activityType" : type.rawValue])
                
                //store as user default
                NSUserDefaults.standardUserDefaults().setInteger(type.rawValue, forKey: "activityType_key")
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    convenience init(delegate: POControllerDelegate) {
        self.init()
        controllerDelegate = delegate
    }
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POControllerCoordinator.freezeControllersNotificationReceived), name: kFreezeControllers, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POControllerCoordinator.thawControllersNotificationReceived), name: kThawControllers, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POControllerCoordinator.stopUpdatingGenerators), name: kPOPdFileWillClose, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, forKeyPath: kFreezeControllers)
        NSNotificationCenter.defaultCenter().removeObserver(self, forKeyPath: kThawControllers)
        NSNotificationCenter.defaultCenter().removeObserver(self, forKeyPath: kPOPdFileWillClose)
    }
    
    //===================================================================================
    //MARK: Generator Loading
    //===================================================================================
    
    func loadGeneratorsForControllers(controllerNames: Set<String>) {
        for controllerName in controllerNames {
            var foundControllerName = false
            for generatorType in generatorTypes {
                if generatorType.controllers.keys.contains(controllerName) {
                    foundControllerName = true
                    if let generator = existingGeneratorInstanceWithType(generatorType) {
                        //first: do we already have an instance in activeGenerators?
                        activateController(controllerName, inGenerator: generator)
                        print("\(controllerName) requested, returning \(generator)")
                        break
                    }
                    else if let generator = generatorForType(generatorType) {
                        //next: is this generatorType one of the framework's included generators?
                        addGeneratorToActiveGenerators(generator)
                        activateController(controllerName, inGenerator: generator)
                        print("\(controllerName) requested, returning \(generator)")
                        break
                    }
                    else if let generator = customGeneratorForType(generatorType) {
                        //finally: has a generator instance been registered?
                        addGeneratorToActiveGenerators(generator)
                        activateController(controllerName, inGenerator: generator)
                        print("\(controllerName) requested, returning \(generator)")
                        break
                    }
                    else {
                        print("\(controllerName) requested, no generator initializer found for \(generatorType)")
                    }
                }
            }
            
            if (!foundControllerName) {
                let controllerNotFoundString = "not found: \(controllerName)"
                print(controllerNotFoundString)
                
                //also print to debug window if available:
                NSNotificationCenter.defaultCenter().postNotificationName(kPdPrintNotification, object: nil, userInfo: ["message" : controllerNotFoundString])
            }
        }
        
        //for fun:
        print(receivableControllersList)
    }
    
    func cleanupGenerators() {
        for generator in activeGenerators {
            for controller in generator.dynamicType.controllers.values {
                controller.active = false
                controller.delegate = nil
            }
        }
        activeGenerators.removeAll(keepCapacity: false)
        timedGenerators.removeAll(keepCapacity: false)
        customGenerators.removeAll(keepCapacity: false)
    }
    
    private func generatorForType(type: POControllerUpdating.Type) -> POControllerUpdating? {
        switch type {
        case is POCoreMotionGenerator.Type:
            return POCoreMotionGenerator()
        case is POPedometerGenerator.Type:
            return POPedometerGenerator()
        case is POCoreLocationGenerator.Type:
            return POCoreLocationGenerator()
        case is POCameraGenerator.Type:
            return POCameraGenerator()
        case is POCoreMotionActivityGenerator.Type:
            return POCoreMotionActivityGenerator()
        case is POAltimeterGenerator.Type:
            return POAltimeterGenerator()
        default:
            print("missing initializer in generatorForType:\(type)")
            return nil
        }
    }
    
    private func customGeneratorForType(type: POControllerUpdating.Type) -> POControllerUpdating? {
        //we can do things a little more generally here, since we are not responsible for allocating / deleting instances of these generators
        for generator in customGenerators {
            if generator.dynamicType == type {
                return generator
            }
        }
        return nil
    }
    
    private func existingGeneratorInstanceWithType(type: POControllerUpdating.Type) -> POControllerUpdating? {
        for generator in activeGenerators {
            if generator.dynamicType == type {
                return generator
            }
        }
        return nil
    }
    
    private func addGeneratorToActiveGenerators(generator: POControllerUpdating) {
        //sets not supported for protocols, contains not supported, manually checking for contains
        var containsGenerator = false
        for activeGenerator in activeGenerators {
            if generator == activeGenerator {
                containsGenerator = true
                break
            }
        }
        if !containsGenerator {
            activeGenerators.append(generator)
            if generator.dynamicType.requiresTimer {
                timedGenerators.append(generator)
            }
        }
    }
    
    //===================================================================================
    //MARK: Generator Updating
    //===================================================================================
    
    func startUpdatingGenerators() {
        for generator in activeGenerators {
            generator.clearControllerSentValues()
            generator.beginUpdating()
        }
        
        if updateTimer == nil {
            updateTimer = NSTimer.scheduledTimerWithTimeInterval((1.0 / 60.0), target: self, selector: #selector(POControllerCoordinator.updateTimerTicked), userInfo: nil, repeats: true)
        }
    }
    
    func stopUpdatingGenerators() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        for generator in activeGenerators {
            generator.endUpdating()
        }
    }
    
    private func activateController(controllerName: String, inGenerator generator: POControllerUpdating) {
        generator.dynamicType.controllers[controllerName]?.delegate = controllerDelegate
        generator.dynamicType.controllers[controllerName]?.active = true
    }
    
    //===================================================================================
    //MARK: Custom Generator Registration
    //===================================================================================
    
    func registerCustomGenerator(generator: POControllerUpdating) {
        //interesting note: does not have to be the same instance to register active
        var contains = false
        for existingGenerator in customGenerators {
            if (generator == existingGenerator) {
                contains = true
                break
            }
        }
        if (!contains) {
            customGenerators.append(generator)
        }
        
        //again for generator types
        contains = false
        for existingGeneratorType in generatorTypes {
            if (generator.dynamicType == existingGeneratorType) {
                contains = true
                break
            }
        }
        if (!contains) {
            generatorTypes.append(generator.dynamicType)
        }
    }
    
    //===================================================================================
    //MARK: Update Timer
    //===================================================================================
    
    func updateTimerTicked() {
        for generator in timedGenerators {
            generator.update()
        }
    }
    
    //===================================================================================
    //MARK: Freeze Controllers
    //===================================================================================
    
    func freezeControllersNotificationReceived() {
        frozen = true
        stopUpdatingGenerators()
    }
    
    func thawControllersNotificationReceived() {
        if frozen {
            frozen = false
            startUpdatingGenerators()
        }
    }
    
    
}

