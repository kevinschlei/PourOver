//
//  CommonExtensions.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

//===================================================================================
//MARK: File Management and Directories
//===================================================================================

let documentsDirectoryFilePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String

//===================================================================================
//MARK: CGPoint
//===================================================================================

/**
Addition operator overload for CGPoint.
*/
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

/**
Subtraction operator overload for CGPoint.
*/
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

extension CGPoint {
    /**
    Returns distance to another point.
    */
    func distanceToPoint(point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx*dx + dy*dy)
    }
}

//===================================================================================
//MARK: CGRect
//===================================================================================

extension CGRect {
    /**
    Returns the center of the rect in its own coordinate space.
    */
    func boundsCenter() -> CGPoint {
        return CGPoint(x: self.width / 2.0, y: self.height / 2.0)
    }
    
    func innerRectWithInset(inset: CGFloat) -> CGRect {
        return CGRect(x: self.origin.x + inset, y: self.origin.y + inset, width: self.size.width - (inset * 2.0), height: self.size.height - (inset * 2.0))
    }
    
    func innerRectWithEdgeInsets(edgeInsets: UIEdgeInsets) -> CGRect {
        return CGRect(x: self.origin.x + edgeInsets.left, y: self.origin.y + edgeInsets.top, width: self.size.width - (edgeInsets.left + edgeInsets.right), height: self.size.height - (edgeInsets.top  + edgeInsets.bottom))
    }
}

//===================================================================================
//MARK: UIColor
//===================================================================================

extension UIColor {
    
    func colorWithHueComponent(hue: CGFloat) -> UIColor {
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getHue(nil, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: hue, saturation: s, brightness: b, alpha: a)
    }
    
    func colorWithSaturationComponent(saturation: CGFloat) -> UIColor {
        var h: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getHue(&h, saturation: nil, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: saturation, brightness: b, alpha: a)
    }
    
    func colorWithBrightnessComponent(brightness: CGFloat) -> UIColor {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getHue(&h, saturation: &s, brightness: nil, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: brightness, alpha: a)
    }
    
    func colorByScalingSaturationComponent(scale: CGFloat) -> UIColor {
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s * scale, brightness: b, alpha: a)
    }
    
    func colorByScalingBrightnessComponent(scale: CGFloat) -> UIColor {
        var h: CGFloat = 0.0
        var b: CGFloat = 0.0
        var s: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * scale, alpha: a)
    }
    
    func invertedColor() -> UIColor {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        self.getRed(&r, green:&g, blue:&b, alpha: &a)
        return UIColor(red: 1.0 - r, green: 1.0 - g, blue:1.0 - b, alpha: a)
    }
    
    func invertedHueCorrectedColor() -> UIColor {
        let invertedColor = self.invertedColor()
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        invertedColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: fmod(h + 0.5, 1.0), saturation: s, brightness: b, alpha: a)
    }
    
}

//===================================================================================
//MARK: Timing
//===================================================================================

func delay(seconds: Double, block: () -> Void) {
    let delayTime = seconds * Double(NSEC_PER_SEC)
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayTime))
    dispatch_after(dispatchTime, dispatch_get_main_queue(), block)
}

//===================================================================================
//MARK: UIView
//===================================================================================

extension UIView {
    
    func showBorder() {
        layer.borderColor = UIColor.randomColor().CGColor
        layer.borderWidth = 1.0
    }
    
    func saveAsPNGToFile(filePath: String) {
        UIGraphicsBeginImageContext(self.bounds.size);
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImagePNGRepresentation(screenShot)?.writeToFile(filePath, atomically: true)
    }
    
}

//===================================================================================
//MARK: Date and Time
//===================================================================================

func timeStringForSeconds(seconds: NSTimeInterval) -> String {
    let date = NSDate(timeIntervalSince1970: seconds)
    let formatter = NSDateFormatter()
    if (seconds / 60.0 >= 60.0) {
        formatter.dateFormat = "H:mm:ss"
    }
    else {
        formatter.dateFormat = "m:ss"
    }
    formatter.timeZone = NSTimeZone(abbreviation: "GMT")
    return formatter.stringFromDate(date)
}

