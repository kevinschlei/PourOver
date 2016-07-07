//
//  POPlaybackTimerView.swift
//  TimerMaker
//
//  Created by kevin on 7/11/15.
//  Copyright © 2015 Bit Shape. All rights reserved.
//

import UIKit

let kPlaybackTime = "POPlaybackTimerView.playbackPercentage"

protocol POPlaybackTimerViewDelegate: class {
    func timerViewDidChangeValue(value: Double, sender: POPlaybackTimerView)
}

class POPlaybackTimerView: UIView, POControllerUpdating {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
  
    weak var delegate: POPlaybackTimerViewDelegate?
    
    let handleView = UIView()
    let midLineView = UIView()
    let leftEdgeView = UIView()
    let rightEdgeView = UIView()
    
    var handleViewColor = UIColor.interfaceColorDark() {
        didSet {
            for subview in handleView.subviews {
                subview.backgroundColor = handleViewColor
            }
        }
    }
    var interfaceColor = UIColor.interfaceColor() {
        didSet {
            midLineView.backgroundColor = interfaceColor
            leftEdgeView.backgroundColor = interfaceColor
            rightEdgeView.backgroundColor = interfaceColor
        }
    }
    
    var secondsTimer: NSTimer?
    
    /**
    Although beginUpdating() and endUpdating() are public, this property should be the entry point for starting and stoping the playback timer.
    */
    var playing: Bool = false {
        didSet {
            if (playing) {
                //if we're at the end, start over at the beginning
                if (playbackPosition >= playbackLength) {
                    playbackPosition = 0
                }
                update()
                startSecondsTimer()
            }
            else {
                stopSecondsTimer()
            }
        }
    }
    
    /**
    User definable maximum playback time in seconds. Default is 60.
    */
    var playbackLength: Double = 60 {
        didSet {
            if (playbackLength <= 0) {
                playbackLength = 1
            }
            update()
        }
    }
    
    /**
    Stores current position in seconds. Used to calculate playback percentage.
    */
    private var playbackPosition: Double = 0.0

    var playbackPercentage: Double {
        get {
            return playbackPosition / playbackLength
        }
    }

    //===================================================================================
    //MARK: Initialization
    //===================================================================================
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let edgeWidth: CGFloat = 2
        let edgeHeight: CGFloat = self.bounds.height * 0.3
        let handleWidth: CGFloat = 3
        
        midLineView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 2)
        midLineView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        midLineView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        midLineView.backgroundColor = interfaceColor
        addSubview(midLineView)
        
        leftEdgeView.frame = CGRect(x: 0, y: 0, width: edgeWidth, height: edgeHeight)
        leftEdgeView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        leftEdgeView.backgroundColor = interfaceColor
        addSubview(leftEdgeView)
        
        rightEdgeView.frame = CGRect(x: 0, y: 0, width: edgeWidth, height: edgeHeight)
        rightEdgeView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        rightEdgeView.backgroundColor = interfaceColor
        addSubview(rightEdgeView)
        
        handleView.frame = CGRect(x: 0, y: 0, width: self.bounds.height, height: self.bounds.height)
        handleView.layer.cornerRadius = 8
        handleView.backgroundColor = UIColor.highlightColorDark().colorWithAlphaComponent(0.4)

        let barView = UIView(frame: CGRect(x: 0, y: 0, width: handleWidth, height: self.bounds.height))
        barView.backgroundColor = handleViewColor
        barView.center = CGPoint(x: handleView.bounds.midX, y: handleView.bounds.midY)
        barView.userInteractionEnabled = false
        handleView.addSubview(barView)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(POPlaybackTimerView.panGestureRecognized(_:)))
        handleView.addGestureRecognizer(panGestureRecognizer)
        
        addSubview(handleView)
        
        //resize view without changing center to allow for handle touch access
        let oldCenter = self.center
        bounds = CGRect(x: 0, y: 0, width: self.bounds.width + handleView.bounds.width, height: self.bounds.height)
        center = oldCenter
        
        rightEdgeView.center = CGPoint(x: midLineView.frame.maxX, y: self.bounds.midY)
        leftEdgeView.center = CGPoint(x: midLineView.frame.minX, y: self.bounds.midY)
        handleView.center = CGPoint(x: midLineView.frame.minX, y: self.bounds.midY)

        backgroundColor = UIColor.clearColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("required init missing")
    }
    
    deinit {
        endUpdating()
    }
    
    //===================================================================================
    //MARK: Timers
    //===================================================================================
    
    func secondsTimerTicked() {
        playbackPosition += 1
        update()
    }
    
    func startSecondsTimer() {
        stopSecondsTimer()
        secondsTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(POPlaybackTimerView.secondsTimerTicked), userInfo: nil, repeats: true)
    }
    
    func stopSecondsTimer() {
        secondsTimer?.invalidate()
        secondsTimer = nil
    }
    
    //===================================================================================
    //MARK: Gesture Recognizers
    //===================================================================================
    
    func panGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.Began, UIGestureRecognizerState.Changed:
            if (gestureRecognizer.state == .Began) {
                //stop updating timer until we release the handle
                stopSecondsTimer()
            }
            
            if let gestureRecognizerView = gestureRecognizer.view {
                let xDrag = gestureRecognizer.translationInView(self).x
                let updatedXPosition = gestureRecognizerView.center.x + xDrag
                let xLimited = min(max(midLineView.frame.minX, updatedXPosition), midLineView.frame.maxX)
                
                gestureRecognizerView.center = CGPoint(x: xLimited, y: self.bounds.midY)
                gestureRecognizer.setTranslation(CGPointZero, inView: self)
                
                //update playback position
                let viewPositionPercentage = (xLimited - midLineView.frame.minX) / midLineView.bounds.width
                playbackPosition = floor(playbackLength * Double(viewPositionPercentage))
                
                //testing
                update()
                
                //view update
                let handlePositionX = midLineView.bounds.width * CGFloat(viewPositionPercentage) + midLineView.frame.minX
                handleView.center = CGPoint(x: handlePositionX, y: self.bounds.midY)
            }
        case UIGestureRecognizerState.Ended, UIGestureRecognizerState.Cancelled:
            //restart playback if we were playing
            if (playing) {
                startSecondsTimer()
            }
            
            //view update (snap)
            let handlePositionX = midLineView.bounds.width * CGFloat(playbackPercentage) + midLineView.frame.minX
            handleView.center = CGPoint(x: handlePositionX, y: self.bounds.midY)
            
        default:
            return
        }
    }
    
    //===================================================================================
    //MARK: POControllerUpdating
    //===================================================================================
    
    static var controllers: [String : POController] = [
        kPlaybackTime : POController(name: kPlaybackTime, min: 0, max: 1)
    ]
    
    static var requiresTimer: Bool = false
    
    func update() {
        if (playbackPosition > playbackLength) {
            playbackPosition = playbackLength
            stopSecondsTimer()
        }
        
        //view update (could be better handled by delegate?)
        let handlePositionX = midLineView.bounds.width * CGFloat(playbackPercentage) + midLineView.frame.minX
        handleView.center = CGPoint(x: handlePositionX, y: self.bounds.midY)
        
        updateValue(playbackPercentage, forControllerNamed: kPlaybackTime)
        
        delegate?.timerViewDidChangeValue(playbackPercentage, sender: self)
    }
    
    func beginUpdating() {
        //we do not support generic beginUpdating control, since this is a user controlled interface
    }
    
    func endUpdating() {
        stopSecondsTimer()
    }
    
}