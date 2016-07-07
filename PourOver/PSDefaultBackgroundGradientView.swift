//
//  PODefaultBackgroundGradientView.swift
//  PourOver
//
//  Created by kevin on 7/18/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import UIKit

class PODefaultBackgroundGradientView: UIView {
    
    private func setupPODefaultBackgroundGradientView() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = [UIColor.appBackgroundColor().CGColor, UIColor.highlightColorLight().CGColor, UIColor.appBackgroundColor().CGColor]
        layer.addSublayer(gradientLayer)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPODefaultBackgroundGradientView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupPODefaultBackgroundGradientView()
    }
    
}
