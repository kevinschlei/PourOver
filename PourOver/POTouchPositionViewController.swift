//
//  POTouchPositionViewController.swift
//  LibraryLoader
//
//  Created by labuser on 6/16/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import UIKit

//constants for controller names:
//note: case-insensitive compared for lookup
let kTouchXPosition = "POTouchPositionViewController.touch.position.x"
let kTouchYPosition = "POTouchPositionViewController.touch.position.y"

class POTouchPositionViewController: UIViewController, POControllerUpdating {
    
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
    //MARK: View Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: if the view bounds change, these values become incorrect
        self.dynamicType.controllers[kTouchXPosition]?.maximumValue = Double(self.view.bounds.width)
        self.dynamicType.controllers[kTouchYPosition]?.maximumValue = Double(self.view.bounds.height)
    }
    
    //===================================================================================
    //MARK: Touches
    //===================================================================================
    
    private final func updateTouches(touches: Set<UITouch>) {
        if let touch = touches.first {
            updateValue(Double(touch.locationInView(self.view).x), forControllerNamed: kTouchXPosition)
            updateValue(Double(touch.locationInView(self.view).y), forControllerNamed: kTouchYPosition)
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateTouches(touches)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if let t = touches {
            updateTouches(t)
        }
    }
    
    //===================================================================================
    //MARK: POControllerUpdating
    //===================================================================================
    
    static var controllers: [String : POController] = [
        kTouchXPosition : POController(name: kTouchXPosition, min: 0, max: 1),
        kTouchYPosition : POController(name: kTouchYPosition, min: 0, max: 1)
    ]
    
    static var requiresTimer: Bool = false
    
    func update() {
    }
    
    func beginUpdating() {
    }
    
    func endUpdating() {
    }
    
}
