//
//  PassiveGlobals.swift
//  PourOver
//
//  Created by labuser on 11/25/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

//===================================================================================
//MARK: UIColor
//===================================================================================

let kInterfaceHue: CGFloat = 0.56

extension UIColor {
    
    class func highlightColorLight() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.05, brightness: 0.93, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func highlightColorDark() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.075, brightness: 0.73, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func darkerHighlightColor() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.075, brightness: 0.53, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func cellFlashColor() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.025, brightness: 1.0, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func appBackgroundColor() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.1, brightness: 0.65, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func interfaceColor() -> UIColor {
        return UIColor(hue: kInterfaceHue, saturation: 0.5, brightness: 0.35, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func interfaceColorDark() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.5, brightness: 0.25, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func interfaceColorMedium() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.25, brightness: 0.4, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func interfaceColorLight() -> UIColor {
        return  UIColor(hue: kInterfaceHue, saturation: 0.06, brightness: 0.77, alpha: 1.0).invertedHueCorrectedColor()
    }
    
    class func randomColor() -> UIColor {
        return  UIColor(hue: CGFloat(Double(arc4random_uniform(1000)) / 1000.0), saturation: CGFloat(Double(arc4random_uniform(1000)) / 1000.0), brightness: CGFloat(Double(arc4random_uniform(1000)) / 1000.0), alpha: 1.0)
    }
}

//===================================================================================
//MARK: UIFont
//===================================================================================

let kPOFontSizeAdjust: CGFloat = 2

extension UIFont {
    
    class func lightAppFontOfSize(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "AvenirNextCondensed-Regular", size: size + kPOFontSizeAdjust) {
            return font
        }
        return UIFont.lightAppFontOfSize(size)
    }
    
    class func boldAppFontOfSize(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "AvenirNextCondensed-Medium", size: size + kPOFontSizeAdjust) {
            return font
        }
        return UIFont.lightAppFontOfSize(size)
    }
    
}

//===================================================================================
//MARK: UIView
//===================================================================================

extension UIView {
    
    func shrinkForTouchDown() {
        self.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
    }
    
    func shrinkALittleForTouchDown() {
        self.layer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
    }
    
    func unshrinkForTouchUp() {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(CATransform3D: self.layer.transform)
        animation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: "easeOut")
        self.layer.addAnimation(animation, forKey: "grow")
        self.layer.transform = CATransform3DIdentity
    }
    
}

//===================================================================================
//MARK: String
//===================================================================================

extension String {
    
    mutating func cleanPdComment() {
        var components: NSArray = self.componentsSeparatedByString(" \\")
        let cleaned = components.componentsJoinedByString("")
        components = cleaned.componentsSeparatedByString("\n")
        self = components.componentsJoinedByString(" ") as String
    }
    
}