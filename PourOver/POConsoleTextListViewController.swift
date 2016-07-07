//
//  POConsoleTextListViewController.swift
//  PourOver
//
//  Created by labuser on 4/1/15.
//  Copyright (c) 2015 labuser. All rights reserved.
//

import UIKit

class POConsoleTextListViewController: UIViewController {

    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    var numberOfRows = 0 {
        didSet {
            updateLabelLayout()
        }
    }
    var labelColor = UIColor.orangeColor()
    var labelFont: UIFont?
    var labelMod = 0

    private var labelCounter = 0;
    private var labels: [UILabel] = []
    private var highlightLabel = UILabel()
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    private func setupCoolTextListViewController() {

    }
    
    convenience init(rows: Int) {
        self.init()
        
        numberOfRows = rows
    }
    
    convenience init(font: UIFont) {
        self.init()

        labelFont = font
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (labelFont == nil) {
            labelFont = UIFont.lightAppFontOfSize(30)
        }
            
        if (numberOfRows == 0) {
            let testLabel = UILabel()
            testLabel.text = "A"
            testLabel.font = labelFont
            testLabel.sizeToFit()
            let fontHeight = testLabel.bounds.height
            numberOfRows = Int(view.bounds.height / fontHeight)
        }
        
        //view setup
        //        view.userInteractionEnabled = false
        
        formatLabel(highlightLabel)
        highlightLabel.alpha = 1.0
        highlightLabel.textColor = UIColor.greenColor()
        view.addSubview(highlightLabel)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(POConsoleTextListViewController.printNotificationReceived(_:)), name: kPdPrintNotification, object: nil)
    }
    
    //===================================================================================
    //MARK: UI Formatting
    //===================================================================================
    
    private func formatLabel(label: UILabel) {
        label.font = labelFont
        label.textColor = labelColor
        label.numberOfLines = 1
        label.lineBreakMode = .ByTruncatingMiddle
        label.textAlignment = .Left
        label.backgroundColor = UIColor.clearColor()
        label.autoresizingMask = [.FlexibleWidth]
        label.alpha = 0.2
    }
    
    func updateLayoutForRows(rows: Int) {
        numberOfRows = rows
        
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        let labelHeight = view.bounds.height / CGFloat(numberOfRows)
        for i in 0..<numberOfRows {
            let newLabel = UILabel(frame: CGRect(x: 0, y: CGFloat(i) * labelHeight, width: view.bounds.width, height: labelHeight))
            formatLabel(newLabel)
            labels.append(newLabel)
            view.addSubview(newLabel)
        }
        
        highlightLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: labelHeight)
    }
    
    func updateLayoutForFont(font: UIFont) {
        labelFont = font
        
        let testLabel = UILabel()
        testLabel.text = "A"
        testLabel.font = labelFont
        testLabel.sizeToFit()
        let fontHeight = testLabel.bounds.height
        numberOfRows = Int(view.bounds.height / fontHeight)
        
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        let labelHeight = view.bounds.height / CGFloat(numberOfRows)
        for i in 0..<numberOfRows {
            let newLabel = UILabel(frame: CGRect(x: 0, y: CGFloat(i) * labelHeight, width: view.bounds.width, height: labelHeight))
            formatLabel(newLabel)
            labels.append(newLabel)
            view.addSubview(newLabel)
        }
        
        highlightLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: labelHeight)
        highlightLabel.font = labelFont
    }
    
    func updateLabelLayout() {
        labels.removeAll()
        
        if (numberOfRows == 0) {
            let testLabel = UILabel()
            testLabel.text = "A"
            testLabel.font = labelFont
            testLabel.sizeToFit()
            let fontHeight = testLabel.bounds.height
            numberOfRows = Int(view.bounds.height / fontHeight)
        }
        
        let labelHeight = view.bounds.height / CGFloat(numberOfRows)
        for i in 0..<numberOfRows {
            let newLabel = UILabel(frame: CGRect(x: 0, y: CGFloat(i) * labelHeight, width: view.bounds.width, height: labelHeight))
            formatLabel(newLabel)
            labels.append(newLabel)
            view.addSubview(newLabel)
        }
        
        highlightLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: labelHeight)
    }
 
    //===================================================================================
    //MARK: Functionality
    //===================================================================================
    
    func setNextLabelText(text: String) {
        let label = labels[labelCounter]
        label.text = text
        if (label.textColor != labelColor) {
            label.textColor = labelColor
        }
        if (highlightLabel.textColor != labelColor) {
            highlightLabel.textColor = labelColor
        }
        highlightLabel.text = label.text
        highlightLabel.center = label.center
        burstAlphaForLabel(label)
        
        labelCounter = (labelCounter + 1) % labels.count
    }
    
    func setNextLabelText(text: String, overrideColor: UIColor) {
        let label = labels[labelCounter]
        label.text = text
        label.textColor = overrideColor
        highlightLabel.text = label.text
        highlightLabel.center = label.center
        highlightLabel.textColor = overrideColor
        burstAlphaForLabel(label)
        
        labelCounter = (labelCounter + 1) % labels.count
    }
    
    private func burstAlphaForLabel(label: UILabel) {
        let preAlpha: CGFloat = label.alpha
        let brightAlpha: CGFloat = 1.0
        label.alpha = brightAlpha
        UIView.animateWithDuration(0.5, animations: {
            label.alpha = preAlpha
        })
    }
    
    func printNotificationReceived(notification: NSNotification) {
        if let message = notification.userInfo?["message"] as? String {
            setNextLabelText(message)
        }
    }
    
    //===================================================================================
    //MARK: Touch Handling
    //===================================================================================
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        testCoolText()
    }
    
    func testCoolText() {
        labelMod += 1
        if (labelMod % 5 == 0) {
            setNextLabelText("error...", overrideColor: UIColor.redColor())
        }
        else {
            setNextLabelText("\(arc4random())")
        }
    }
}
