//
//  AppDelegate.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit
import GTMOAuth2

let kPdPrintNotification = "kPdPrintNotification"

@UIApplicationMain
class POAppDelegate: UIResponder, UIApplicationDelegate, PdReceiverDelegate, POPdListener, POControllerDelegate {

    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    var window: UIWindow?
    var audioController: PdAudioController!
    
    //===================================================================================
    //MARK: Custom Generator References
    //===================================================================================
    
    var playbackTimerView: POPlaybackTimerView?
    
    lazy var touchViewController: POTouchPositionViewController = {
        let _touchViewController = POTouchPositionViewController()
        _touchViewController.view.backgroundColor = UIColor.orangeColor()
        return _touchViewController
        }()
    
    var controllersRequested: Set<String> = []
    let controllerCoordinator = POControllerCoordinator()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {        
        //set POControllerCoordinator controller delegate:
        controllerCoordinator.controllerDelegate = self
        
        //create the libpd audio controller:
        audioController = PdAudioController()
        audioController.configurePlaybackWithSampleRate(48000, numberChannels: 2, inputEnabled: true, mixingEnabled: true)
        audioController.configureTicksPerBuffer(4) //buffer size of 256

        //set the POAppDelegate as the PdBase delegate (methods below):
        POPdBase.setDelegate(self)
        
        //subscribe for loadbang 'patchLoaded' message
        POPdBase.subscribe("patchLoaded")
        
        //set audio controller to active:
        audioController.active = true
        
        //global tint color (
        window?.tintColor = UIColor.interfaceColor()
        
        //appearance
        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName : UIColor.interfaceColorDark(),
            NSFontAttributeName : UIFont.boldAppFontOfSize(18)
        ]
        
        //notification registration
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POAppDelegate.pdFileWillLoadNotificationReceived), name: kPOPdFileWillLoad, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POAppDelegate.pdFileDidLoadNotificationReceived), name: kPOPdFileDidLoad, object: nil)
        
        //defaults registration
        if NSUserDefaults.standardUserDefaults().objectForKey("activityType_key") == nil {
            let defaultType: POActivityType = .Walking
            NSUserDefaults.standardUserDefaults().setInteger(defaultType.rawValue, forKey: "activityType_key")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        audioController.active = false
    }

    func applicationDidEnterBackground(application: UIApplication) {
        audioController.active = false
    }

    func applicationWillEnterForeground(application: UIApplication) {
        audioController.active = true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        audioController.active = true
        controllerCoordinator.startUpdatingGenerators()
    }

    func applicationWillTerminate(application: UIApplication) {
        audioController.active = false
        controllerCoordinator.stopUpdatingGenerators()
    }
    
    //===================================================================================
    //MARK: Notifications
    //===================================================================================
    
    func pdFileWillLoadNotificationReceived() {
        controllersRequested.removeAll()
    }
    
    func pdFileDidLoadNotificationReceived() {
        //always add CMMotionActivityManager.activity.type
        controllersRequested.insert("CMMotionActivityManager.activity.type")
        
        controllerCoordinator.loadGeneratorsForControllers(controllersRequested)
        controllerCoordinator.startUpdatingGenerators()
    }
    
    func pdFileDidCloseNotificationReceived() {
    }
    
    //===================================================================================
    //MARK: POPdBaseListener Delegate Methods
    //===================================================================================
    
    func psrControllerRequest(controller: UnsafePointer<CChar>) {
        if let source = String.fromCString(controller) {
            controllersRequested.insert(source)
        }
    }
    
    //===================================================================================
    //MARK: POControllerDelegate
    //===================================================================================
    
    func valueChanged(value: Double, controllerName: UnsafePointer<CChar>, instance: Int?) {
        if let i = instance {
            let list = UnsafeMutablePointer<Float>.alloc(2)
            list[0] = Float(i)
            list[1] = Float(value)
            POPdBase.sendFloatList(UnsafeMutablePointer<Float>(list), count: 2, toConstCharReceiver: controllerName)
        }
        else {
            POPdBase.sendFloat(Float(value), toConstCharReceiver: controllerName)
        }
    }
    
    //===================================================================================
    //MARK: PdReceiverDelegate
    //===================================================================================
    
    func receivePrint(message: String!) {
        print(message)
        NSNotificationCenter.defaultCenter().postNotificationName(kPdPrintNotification, object: nil, userInfo: ["message" : message])
    }
    
    func receiveBangFromSource(source: String!) {
        //leaving this in for testing only, until we're reasonably sure that we've received all the controller requests before the openFile: method returns
        if source == "patchLoaded" {
            print("loadbang patchLoaded")
        }
    }
}

