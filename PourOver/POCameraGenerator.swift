
//
//  POCameraGenerator.swift
//  PourOver
//
//  Created by Aidan Menuge on 12/6/15.
//  Copyright © 2015 labuser. All rights reserved.
//
import UIKit
import GLKit
import Foundation
import AVFoundation
import CoreMedia

/*protocol CameraControllerDelegate: class {
func cameraController(cameraController:POCameraGenerator, didDetectFaces faces:Array<(id:Int, frame:CGRect)>)
}*/

enum CameraControllerPreviewType {
    case PreviewLayer
    case Manual
}

extension AVCaptureWhiteBalanceGains {
    mutating func gainsRange(minV:Float, maxV: Float) {
        blueGain = max(min(blueGain, maxV), minV)
        redGain = max(min(redGain, maxV), minV)
        greenGain = max(min(greenGain, maxV), minV)
    }
}

class WhiteBalanceValues {
    var temperature:Float
    var tint:Float
    
    init(temperature:Float, tint:Float) {
        self.temperature = temperature
        self.tint = tint
    }
    
    convenience init(temperatureAndTintValues:AVCaptureWhiteBalanceTemperatureAndTintValues) {
        self.init(temperature: temperatureAndTintValues.temperature, tint:temperatureAndTintValues.tint)
    }
}

//===================================================================================
//MARK: POCameraGenerator
//===================================================================================

var kTemperatureValue = "AVCaptureDevice.whiteBalance.temperature"
var kTintValue = "AVCaptureDevice.whiteBalance.tint"
var kCurrentISO = "AVCaptureDevice.ISO"
var kCurrentLensPosition = "AVCaptureDevice.lensPosition"
var kCurrentExposureDuration = "AVCaptureDevice.exposureDuration"
var kdeviceWhiteBalanceGains = "AVCaptureDevice.deviceWhiteBalanceGains"

class POCameraGenerator: NSObject, POControllerUpdating  {
    //weak var delegate:CameraControllerDelegate?
    var previewType: CameraControllerPreviewType?
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    private var sessionQueue:dispatch_queue_t = dispatch_queue_create ("potato", DISPATCH_QUEUE_SERIAL)
    private var pictureOutput:AVCaptureStillImageOutput!
    private var videoOutput:AVCaptureVideoDataOutput!
    private var metadataOutput:AVCaptureMetadataOutput!
    private var session:AVCaptureSession!
    private var backCamera:AVCaptureDevice?
    private var frontCamera:AVCaptureDevice?
    private var selectedCamera:AVCaptureDevice?
    
    private let lensPositionContext = 0
    private let adjustingFocusContext = 0
    private let adjustingExposureContext = 0
    private let adjustingWhiteBalanceContext = 0
    private let exposureDuration = 0
    private let ISO = 0
    private let exposureTargetOffsetContext = 0
    private let deviceWhiteBalanceGainsContext = 0
    
    //private var controlObservers = [String: [AnyObject]]()
    
    let CameraControllerDidStartSession = "CameraControllerDidStartSession"
    let activeCamera = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
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
        kTemperatureValue : POController(name: kTemperatureValue, min: 3500, max: 9500),
        kTintValue : POController(name: kTintValue, min: -150, max: 150),
        kCurrentISO : POController(name: kCurrentISO, min: 32, max: 1600),
        kCurrentLensPosition : POController(name: kCurrentLensPosition, min: 0.0, max: 1.0),
        kCurrentExposureDuration : POController(name: kCurrentExposureDuration, min: 0, max: 1000), //not sure about this min/max yet
        kdeviceWhiteBalanceGains: POController(name: kdeviceWhiteBalanceGains, min: 1.0, max: 1000)
    ]
    
    static var requiresTimer: Bool = true
    
    func update() {
        updateValue(Double(lensPositionContext), forControllerNamed: kCurrentLensPosition)
        if let temperature = currentTemp() {
            updateValue(Double(temperature), forControllerNamed: kTemperatureValue)
        }
        if let tint = currentTint() {
            updateValue(Double(tint), forControllerNamed: kTintValue)
        }
        updateValue(Double(ISO), forControllerNamed: kCurrentISO)
        updateValue(Double(exposureDuration), forControllerNamed: kCurrentExposureDuration)
        updateValue(Double(deviceWhiteBalanceGainsContext), forControllerNamed: kdeviceWhiteBalanceGains)
    }
    
    func beginUpdating() {
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        if previewType == .PreviewLayer {
            
        }
        
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        switch authorizationStatus {
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted:Bool) -> Void in
                if granted {
                    self.cameraChecker()
                }
                else {
                    self.accessDenied()
                }
            })
        case .Authorized:
            cameraChecker()
        case .Denied, .Restricted:
            accessDenied()
        }
        startRunning()
        
    }
    
    func endUpdating() {
        stopRunning()
        
    }
    
    func performConfiguration(block: (() -> Void)) {
        dispatch_async(sessionQueue) { () -> Void in
            block()
        }
    }
    
    
    /*required init(previewType:CameraControllerPreviewType, delegate:CameraControllerDelegate) {
    self.delegate = delegate
    self.previewType = previewType
    
    super.init()
    
    
    }*/
    
    func initialize() {
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        if previewType == .PreviewLayer {
            
        }
        
        let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        switch authorizationStatus {
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted:Bool) -> Void in
                if granted {
                    self.cameraChecker()
                }
                else {
                    self.accessDenied()
                }
            })
        case .Authorized:
            cameraChecker()
        case .Denied, .Restricted:
            accessDenied()
        }
    }
    
    func cameraChecker() {
        
        performConfiguration { () -> Void in
            for device in self.activeCamera as! [AVCaptureDevice] {
                if device.position == .Back {
                    self.backCamera = device
                }
                else if device.position == .Front {
                    self.frontCamera = device
                }
            }
            self.selectedCamera = self.backCamera
            var chosenInput: AVCaptureDeviceInput? = nil
            
            do {
                chosenInput = try AVCaptureDeviceInput(device: self.selectedCamera) as AVCaptureDeviceInput
            }
            catch let error as NSError {
                print("error creating AVCaptureDeviceInput \(error)")
            }
            
            if let backCameraInput = chosenInput {
                if self.session.canAddInput(backCameraInput) {
                    self.session.addInput(backCameraInput)
                }
            }
        }
    }
    
    func currentTemp() -> Float? {
        if let gains = selectedCamera?.deviceWhiteBalanceGains {
            let tempAndTint = selectedCamera?.temperatureAndTintValuesForDeviceWhiteBalanceGains(gains)
            return tempAndTint?.temperature
        }
        else {
            return nil
        }
    }
    
    func currentTint() -> Float? {
        if let gains = selectedCamera?.deviceWhiteBalanceGains {
            let tempAndTint = selectedCamera?.temperatureAndTintValuesForDeviceWhiteBalanceGains(gains)
            return tempAndTint?.tint
        }
        else {
            return nil
        }
    }
    
    func currentISO() -> Float {
        return (selectedCamera?.ISO)!
    }
    
    func currentLensPosition() -> Float? {
        return self.selectedCamera?.lensPosition
    }
    
    func currentExposureDuration() -> Float? {
        if let exposureDuration = selectedCamera?.exposureDuration {
            return Float(CMTimeGetSeconds(exposureDuration))
        }
        else {
            return nil
        }
    }
    
    func configPictureOutput () {
        performConfiguration { () -> Void in
            self.pictureOutput = AVCaptureStillImageOutput()
            self.pictureOutput.outputSettings = [
                AVVideoCodecKey : AVVideoCodecJPEG,
                AVVideoQualityKey: 0.9]
        }
    }
    
    /*func configVideoOutput () {
    performConfiguration { () -> Void in
    self.videoOutput = AVCaptureVideoDataOutput()
    self.videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
    if self.session.canAddOutput(self.videoOutput) {
    self.session.addOutput(self.videoOutput)
    }
    
    }
    }*/
    
    /*func configFace() {
    performConfiguration { () -> Void in
    self.metadataOutput = AVCaptureMetadataOutput()
    self.metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
    
    if self.session.canAddOutput(self.metadataOutput) {
    self.session.addOutput(self.metadataOutput)
    }
    
    }
    }*/
    
//    func observeValues() {
//        selectedCamera?.addObserver(self, forKeyPath: "lensPosition", options: .New, context: &lensPositionContext)
//        selectedCamera?.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: &adjustingFocusContext)
//        selectedCamera?.addObserver(self, forKeyPath: "adjustingExposure", options: .New, context: &adjustingExposureContext)
//        selectedCamera?.addObserver(self, forKeyPath: "adjustingWhiteBalance", options: .New, context: &adjustingWhiteBalanceContext)
//        selectedCamera?.addObserver(self, forKeyPath: "exposureDuration", options: .New, context: &exposureDuration)
//        selectedCamera?.addObserver(self, forKeyPath: "ISO", options: .New, context: &ISO)
//        selectedCamera?.addObserver(self, forKeyPath: "deviceWhiteBalanceGains", options: .New, context: &deviceWhiteBalanceGainsContext)
//    }
    
    
//    func unobserveValues() {
//        selectedCamera?.removeObserver(self, forKeyPath: "lensPosition", context: &lensPositionContext)
//        selectedCamera?.removeObserver(self, forKeyPath: "adjustingFocus", context: &adjustingFocusContext)
//        selectedCamera?.removeObserver(self, forKeyPath: "adjustingExposure", context: &adjustingExposureContext)
//        selectedCamera?.removeObserver(self, forKeyPath: "adjustingWhiteBalance", context: &adjustingWhiteBalanceContext)
//        selectedCamera?.removeObserver(self, forKeyPath: "exposureDuration", context: &exposureDuration)
//        selectedCamera?.removeObserver(self, forKeyPath: "ISO", context: &ISO)
//        selectedCamera?.removeObserver(self, forKeyPath: "deviceWhiteBalanceGains", context: &deviceWhiteBalanceGainsContext)
//    }
    
    func startRunning() {
        performConfiguration { () -> Void in
//            self.observeValues()
            self.session.startRunning()
            NSNotificationCenter.defaultCenter().postNotificationName(self.CameraControllerDidStartSession, object: self)
        }
    }
    
    func stopRunning() {
//        performConfiguration { () -> Void in
//            self.unobserveValues()
            self.session.stopRunning()
//        }
    }
    
    func configureSession() {
        cameraChecker()
        configPictureOutput()
        //configFace()
        
        if previewType == .Manual {
            //configVideoOutput()
        }
    }
    func accessDenied () {
        
    }
    
}