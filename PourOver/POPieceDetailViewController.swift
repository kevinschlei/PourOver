//
//  POPieceDetailViewController.swift
//  PourOver
//
//  Created by labuser on 11/26/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

//===================================================================================
//MARK: Global Functions
//===================================================================================

func imageNameForActivityType(activityType: POActivityType) -> String? {
    switch activityType {
    case .Unknown:
        return nil
    case .Walking:
        return "mode-walking.png"
    case .Running:
        return "mode-running.png"
    case .Cycling:
        return "mode-cycling.png"
    case .Automotive:
        return "mode-driving.png"
    }
}

class POPieceDetailViewController: POViewController, POHoursMinutesSecondsPickerViewControllerDelegate, POPlaybackTimerViewDelegate, POModeCollectionViewControllerDelegate {
    
    enum POPlaybackButton: Int {
        case PlayStop
        case Freeze
        case Mode
        case Visualize
        case Length
    }
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    var pieceTitle: String?
    var defaultLength: NSTimeInterval = 60 {
        didSet {
            playbackLengthLabel.text = timeStringForSeconds(defaultLength)
            if let timerView = playbackTimerView {
                timerView.playbackLength = defaultLength
                playbackCurrentTimeLabel.text = timeStringForSeconds(timerView.playbackPercentage * defaultLength)
            }
        }
    }
    
    var playbackButtons: [UIButton] = []
    var playbackButtonLabels: [UILabel] = []
    let crossHairsView = UIView()
    
    //timer view
    var playbackTimerView: POPlaybackTimerView?
    let playbackLengthLabel = UILabel()
    let playbackCurrentTimeLabel = UILabel()
    
    //debug text view
    let coolTextViewController = POConsoleTextListViewController(rows: 12)
    var labelMod = 0
    
    //piece length picker view controller
    lazy var playbackLengthPickerViewController: POHoursMinutesSecondsPickerViewController = {
        let picker = POHoursMinutesSecondsPickerViewController()
        picker.delegate = self
        return picker
    }()
    
    lazy var lengthPopoverController: POPopoverController = {
        let popover = POPopoverController()
        popover.borderColor = UIColor.interfaceColorMedium()
        popover.dimsBackground = true
        return popover
    }()
    
    //piece length picker view controller
    lazy var modeCollectionViewController: POModeCollectionViewController = {
        let modeViewController = POModeCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        modeViewController.delegate = self
        return modeViewController
    }()
    
    lazy var modePopoverController: POPopoverController = {
        let popover = POPopoverController()
        popover.borderColor = UIColor.interfaceColorMedium()
        popover.dimsBackground = true
        return popover
    }()
    
    let questionMarkButton = UIButton(type: .System)
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.highlightColorLight()
        
        title = pieceTitle
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
//        let topColor = UIColor.appBackgroundColor().colorByScalingBrightnessComponent(0.8).colorByScalingSaturationComponent(1.2)
        let topColor = UIColor.appBackgroundColor()
        let bottomColor = UIColor.highlightColorLight().colorWithBrightnessComponent(0.1)
        gradientLayer.colors = [topColor.CGColor, bottomColor.CGColor]
        gradientLayer.locations = [0, 0.85]
        view.layer.addSublayer(gradientLayer)
        
        //playback buttons
        let buttonImageNames = [
            "play-button.png",
            "freeze-button.png",
            "",
            "visualize-button.png",
            "clock-button.png"
        ]
        //playback button labels
        let buttonLabelTexts = [
            "Play",
            "Freeze",
            "Mode",
            "Visualize",
            "Length"
        ]
        
        for i in 0..<buttonLabelTexts.count {
            //buttons
            let button = UIButton(type: .System)
             button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            if let buttonImage = UIImage(named: buttonImageNames[i])?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate) {
                button.setImage(buttonImage, forState: UIControlState.Normal)
            }
            button.addTarget(self, action: #selector(POPieceDetailViewController.playbackButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            button.addTarget(self, action: #selector(POPieceDetailViewController.buttonTouchDown(_:)), forControlEvents: UIControlEvents.TouchDown)
            button.addTarget(self, action: #selector(POPieceDetailViewController.buttonTouchUp(_:)), forControlEvents: [UIControlEvents.TouchUpInside, UIControlEvents.TouchDragExit])
            button.tag = i
            button.tintColor = UIColor.interfaceColorDark()
            playbackButtons.append(button)
            
            //labels
            let label = buttonLabel()
            label.text = buttonLabelTexts[i]
            playbackButtonLabels.append(label)
            
            view.addSubview(button)
            view.addSubview(label)
        }
        
        questionMarkButton.setTitle("?", forState: .Normal)
        questionMarkButton.titleLabel?.font = UIFont.boldAppFontOfSize(36)
        questionMarkButton.setTitleColor(UIColor.interfaceColorDark().colorWithAlphaComponent(0.4), forState: .Normal)
        questionMarkButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        questionMarkButton.addTarget(self, action: #selector(POPieceDetailViewController.questionMarkButtonPressed(_:)), forControlEvents: .TouchUpInside)
        questionMarkButton.addTarget(questionMarkButton, action: #selector(UIView.shrinkForTouchDown), forControlEvents: [.TouchDown, .TouchDragEnter])
        questionMarkButton.addTarget(questionMarkButton, action: #selector(UIView.unshrinkForTouchUp), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchDragExit])
        questionMarkButton.center = CGPoint(x: view.bounds.width - questionMarkButton.bounds.midX - 5, y: questionMarkButton.bounds.midY + 5)
        questionMarkButton.tintColor = UIColor.interfaceColorDark()
        questionMarkButton.adjustsImageWhenHighlighted = false
        view.addSubview(questionMarkButton)
        
        //layout
        spaceButtonsAndLabelsUpTo(3)
        
        //freeze begins disabled
        playbackButtons[POPlaybackButton.Freeze.rawValue].enabled = false
        
        //crosshair view
        crossHairsView.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        crossHairsView.backgroundColor = UIColor.clearColor()
        crossHairsView.alpha = 0.3
        let verticalCrossHairView = UIView(frame: CGRect(x: crossHairsView.bounds.size.width / 2.0, y: 0, width: 1, height: crossHairsView.bounds.size.height))
        verticalCrossHairView.backgroundColor = UIColor.interfaceColorDark()
        let horizontalCrossHairView = UIView(frame: CGRect(x: 0, y: crossHairsView.bounds.size.height / 2.0, width: crossHairsView.bounds.size.width, height: 1))
        horizontalCrossHairView.backgroundColor = UIColor.interfaceColorDark()
        crossHairsView.addSubview(verticalCrossHairView)
        crossHairsView.addSubview(horizontalCrossHairView)
        crossHairsView.center = self.playbackButtons[0].center
        crossHairsView.userInteractionEnabled = false
        view.addSubview(crossHairsView)
        
        //playback timer view
        playbackTimerView = POPlaybackTimerView(frame: CGRect(x: playbackButtons[0].frame.minX + 11, y: playbackButtons[0].frame.minY - 60, width: playbackButtons[2].frame.maxX - (playbackButtons[0].frame.minX + 11), height: 35))
        playbackTimerView!.delegate = self
        playbackTimerView!.playbackLength = defaultLength
        view.addSubview(playbackTimerView!)
        
        //register generator with POControllerCoordinator
        if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
            appDelegate.controllerCoordinator.registerCustomGenerator(playbackTimerView!)
        }
        
        //piece title label
        //title label, goes in contentView
        if let _ = pieceTitle {
            addDefaultTitleViewWithText(pieceTitle!)
        }
        
        addDefaultBackButton()

        
        //length button
        playbackButtons[POPlaybackButton.Length.rawValue].center = CGPoint(x: playbackButtons[POPlaybackButton.Visualize.rawValue].center.x, y: playbackTimerView!.center.y)
        playbackButtonLabels[POPlaybackButton.Length.rawValue].center = CGPoint(x: playbackButtons[POPlaybackButton.Length.rawValue].center.x, y: playbackButtons[POPlaybackButton.Length.rawValue].frame.maxY + playbackButtonLabels[POPlaybackButton.Length.rawValue].bounds.midY)
        
        //length label
        playbackLengthLabel.frame = CGRect(x: 0, y: 0, width: 75, height: 16)
        playbackLengthLabel.font = UIFont.lightAppFontOfSize(12)
        playbackLengthLabel.textAlignment = .Center
        playbackLengthLabel.textColor = UIColor.interfaceColor()
        playbackLengthLabel.center = CGPoint(x: playbackButtons[POPlaybackButton.Mode.rawValue].frame.maxX, y: playbackTimerView!.frame.minY - playbackLengthLabel.bounds.midY)
        playbackLengthLabel.text = timeStringForSeconds(defaultLength)
        view.addSubview(playbackLengthLabel)
        
        //playback current time
        playbackCurrentTimeLabel.frame = CGRect(x: 0, y: 0, width: 75, height: 16)
        playbackCurrentTimeLabel.font = UIFont.lightAppFontOfSize(12)
        playbackCurrentTimeLabel.textAlignment = .Center
        playbackCurrentTimeLabel.textColor = UIColor.interfaceColor()
        playbackCurrentTimeLabel.center = CGPoint(x: playbackButtons[POPlaybackButton.PlayStop.rawValue].frame.minX + 11, y: playbackTimerView!.frame.minY - playbackLengthLabel.bounds.midY)
        playbackCurrentTimeLabel.text = timeStringForSeconds(0)
        view.addSubview(playbackCurrentTimeLabel)
        
        //debug text scroll view
        coolTextViewController.view.frame = view.bounds.innerRectWithEdgeInsets(UIEdgeInsets(top: CGRectGetMaxY(titleView!.frame), left: 10, bottom: view.bounds.height - (playbackCurrentTimeLabel.frame.minY - 10), right: 10))
        coolTextViewController.view.userInteractionEnabled = false
        coolTextViewController.labelColor = UIColor.interfaceColorDark()
        coolTextViewController.updateLayoutForFont(UIFont.lightAppFontOfSize(16))
        coolTextViewController.willMoveToParentViewController(self)
        self.addChildViewController(coolTextViewController)
        self.view.addSubview(coolTextViewController.view)
        coolTextViewController.didMoveToParentViewController(self)
        
        //set default activity type
        //this will be the last used if automatic activity detection is turned on
        let defaultActivityType = NSUserDefaults.standardUserDefaults().integerForKey("activityType_key")
        if let activityType = POActivityType(rawValue: defaultActivityType) {
            setActivityType(activityType)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POPieceDetailViewController.activityGeneratorActivityTypeDidChange(_:)), name: kPOCoreMotionActivityGeneratorActivityTypeDidChange, object: nil)
    }
    
    //===================================================================================
    //MARK: Interface
    //===================================================================================
    
    private func buttonLabel() -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 75, height: 20))
        label.font = UIFont.lightAppFontOfSize(12)
        label.textAlignment = .Center
        label.textColor = UIColor.interfaceColor()
        return label
    }
    
    private func spaceButtonsAndLabelsUpTo(index: Int) {
        for i in 0...index {
            let button = playbackButtons[i]
            let label = playbackButtonLabels[i]
            let spacerX = self.view.bounds.width / CGFloat(index + 1)
            let interButtonDistanceX = (self.view.bounds.width - (button.bounds.width * CGFloat(index + 1))) / CGFloat(index + 1)
            let positionY = self.view.bounds.height * 0.875
            button.center = CGPoint(x: CGFloat(i) * spacerX + button.bounds.midX + (interButtonDistanceX / 2.0), y: positionY)
            label.center = CGPoint(x: button.center.x, y: button.frame.maxY + label.bounds.midY)
        }
    }
    
    func buttonTouchDown(sender: UIButton) {
        sender.shrinkForTouchDown()
    }
    
    func buttonTouchUp(sender: UIButton) {
        sender.unshrinkForTouchUp()
    }
    
    func playbackButtonPressed(sender: UIButton) {
        if let buttonType = POPlaybackButton(rawValue: sender.tag) {
            switch buttonType {
            case .PlayStop:
                print("PlayStop pressed")
                togglePlayStop()
            case .Freeze:
                print("Freeze pressed")
                toggleFreezeControllers()
            case .Mode:
                print("mode pressed")
                modeButtonPressed(sender)
            case .Visualize:
                print("Visualize pressed")
            case .Length:
                playbackLengthButtonPressed(sender)
            }
            
            //spring animation:
            UIView.animateWithDuration(0.4,
                delay: 0.0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions.BeginFromCurrentState,
                animations: {
                    self.crossHairsView.center = self.playbackButtons[sender.tag].center
                },
                completion: nil)
        }
    }
    
    func playbackLengthButtonPressed(sender: UIButton) {
        playbackLengthPickerViewController.currentTime = defaultLength
        lengthPopoverController.presentViewController(playbackLengthPickerViewController, fromRect: sender.frame, inViewController: self, permittedArrowDirections: .Any, preferredSize: CGSize(width: 200, height: 200), animated: true)
    }
    
    func modeButtonPressed(sender: UIButton) {
        modePopoverController.presentViewController(modeCollectionViewController, fromRect: sender.frame, inViewController: self, permittedArrowDirections: .Any, preferredSize: CGSize(width: 260, height: 70), animated: true)
    }
    
    func questionMarkButtonPressed(sender: UIButton) {
        let tableViewController = POReceivableControllersListTableViewController(style: .Plain)
        navigationController?.pushViewController(tableViewController, animated: true)
    }
    
    func setModeButtonToImageNamed(imageName: String?) {
        let modeButton = self.playbackButtons[POPlaybackButton.Mode.rawValue]
        if let name = imageName {
            modeButton.setImage(UIImage(named: name)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            modeButton.tintColor = UIColor.interfaceColorDark()
            modeButton.setBackgroundImage(nil, forState: .Normal)
            modeButton.setTitle(nil, forState: .Normal)
        }
        else {
            if let image = modeButton.imageView?.image {
                modeButton.setBackgroundImage(image.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            }
            modeButton.setImage(nil, forState: .Normal)
            modeButton.setTitle("?", forState: .Normal)
            modeButton.tintColor = UIColor.interfaceColorDark().colorWithAlphaComponent(0.3)
            modeButton.titleLabel?.font = UIFont.lightAppFontOfSize(36)
            modeButton.setTitleColor(UIColor.interfaceColorDark(), forState: .Normal)
        }
    }
    
    //===================================================================================
    //MARK: POHoursMinutesSecondsPickerViewControllerDelegate
    //===================================================================================
    
    func hoursMinutesSecondsPickerDidUpdateTime(time: NSTimeInterval, sender: POHoursMinutesSecondsPickerViewController) {
        defaultLength = time
        playbackTimerView?.playbackLength = time
        playbackTimerView?.update()
    }
    
    //===================================================================================
    //MARK: POPlaybackTimerViewDelegate
    //===================================================================================
    
    func timerViewDidChangeValue(value: Double, sender: POPlaybackTimerView) {
        playbackCurrentTimeLabel.text = timeStringForSeconds(value * defaultLength)
        if (value >= 1.0) {
            let playStopLabel = playbackButtonLabels[POPlaybackButton.PlayStop.rawValue]
            if playStopLabel.text == "Stop" {
                stop()
            }
            thaw()
        }
    }
    
    //===================================================================================
    //MARK: POModeCollectionViewControllerDelegate
    //===================================================================================
    
    func modeCollectionViewControllerDidSelectActivityType(activityType: POActivityType) {
        setActivityType(activityType)
        modePopoverController.dismissPopoverAnimated(true)
    }
    
    //===================================================================================
    //MARK: Functionality
    //===================================================================================
    
    func setActivityType(activityType: POActivityType) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
            appDelegate.controllerCoordinator.activityType = activityType
            if let imageName = imageNameForActivityType(activityType) {
                setModeButtonToImageNamed(imageName)
            }
        }
    }
    
    func togglePlayStop() {
        let playStopLabel = playbackButtonLabels[POPlaybackButton.PlayStop.rawValue]
        if playStopLabel.text == "Play" {
            play()
        }
        else {
            stop()
        }
        thaw()
    }
    
    func play() {
        let playStopLabel = playbackButtonLabels[POPlaybackButton.PlayStop.rawValue]
        let playStopButton = playbackButtons[POPlaybackButton.PlayStop.rawValue]
        POPdBase.sendBangToConstCharReceiver("play")
        playStopLabel.text = "Stop"
        playStopButton.setImage(UIImage(named: "stop-button.png"), forState: .Normal)
        playbackTimerView?.playing = true
        
        playbackButtons[POPlaybackButton.Freeze.rawValue].enabled = true
    }
    
    func stop() {
        let playStopLabel = playbackButtonLabels[POPlaybackButton.PlayStop.rawValue]
        let playStopButton = playbackButtons[POPlaybackButton.PlayStop.rawValue]
        POPdBase.sendBangToConstCharReceiver("stop")
        playStopLabel.text = "Play"
        playStopButton.setImage(UIImage(named: "play-button.png"), forState: .Normal)
        playbackTimerView?.playing = false
        
        playbackButtons[POPlaybackButton.Freeze.rawValue].enabled = false
    }
    
    func toggleFreezeControllers() {
        let freezeLabel = playbackButtonLabels[POPlaybackButton.Freeze.rawValue]
        if freezeLabel.text == "Freeze" {
            freeze()
            playbackTimerView?.playing = false
        }
        else {
            thaw()
            playbackTimerView?.playing = true
        }
    }
    
    func freeze() {
        let freezeLabel = playbackButtonLabels[POPlaybackButton.Freeze.rawValue]
        let freezeButton = playbackButtons[POPlaybackButton.Freeze.rawValue]
        POPdBase.sendBangToConstCharReceiver("freeze")
        NSNotificationCenter.defaultCenter().postNotificationName(kFreezeControllers, object: nil)
        freezeLabel.text = "Thaw"
        freezeButton.setImage(UIImage(named: "thaw-button.png"), forState: .Normal)
    }
    
    func thaw() {
        let freezeLabel = playbackButtonLabels[POPlaybackButton.Freeze.rawValue]
        let freezeButton = playbackButtons[POPlaybackButton.Freeze.rawValue]
        POPdBase.sendBangToConstCharReceiver("thaw")
        NSNotificationCenter.defaultCenter().postNotificationName(kThawControllers, object: nil)
        freezeLabel.text = "Freeze"
        freezeButton.setImage(UIImage(named: "freeze-button.png"), forState: .Normal)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //===================================================================================
    //MARK: Notifications
    //===================================================================================
    
    func activityGeneratorActivityTypeDidChange(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let activityType = userInfo["activityType"] {
                if let type: POActivityType = POActivityType(rawValue: (activityType as! NSNumber).integerValue) {
                    if let imageName = imageNameForActivityType(type) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.setModeButtonToImageNamed(imageName)
                        }
                    }
                }
            }
        }
    }
    
}
