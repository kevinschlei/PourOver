//
//  POViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import Foundation

class POViewController: UIViewController, UIScrollViewDelegate {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    /*
     This is the view that shrinks / recedes when the scrollView scrolls up.
     */
    var titleView: UIView? {
        didSet {
            if let _ = titleView {
                titleView!.center = CGPoint(x: Int(CGRectGetWidth(view.bounds) / 2.0), y: 120)
                if view.subviews.indexOf(titleView!) == nil {
                    view.addSubview(titleView!)
                }
            }
        }
    }
    
    var scrollViewContentOffsetStart: CGFloat = 0.0
    
    private var leftButtonIsBackButton = false

    private let buttonEdge: CGFloat = 46.0
    var leftTitleButton: UIButton? {
        didSet {
            //setup
            if var button = leftTitleButton {
                formatTitleButton(&button)
                button.center = CGPoint(x: Int(buttonEdge * 0.7), y:  Int(buttonEdge * 0.7))
                button.addTarget(self, action: #selector(POViewController.leftButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                if view.subviews.indexOf(button) == nil {
                    view.addSubview(button)
                }
            }
            leftButtonIsBackButton = false
        }
    }
    var rightTitleButton: UIButton? {
        didSet {
            //setup
            if var button = rightTitleButton {
                formatTitleButton(&button)
                let viewWidth = CGRectGetWidth(view.bounds)
                button.center = CGPoint(x: Int(viewWidth - buttonEdge * 0.7), y:  Int(buttonEdge * 0.7))
                button.addTarget(self, action: #selector(POViewController.rightButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                if view.subviews.indexOf(button) == nil {
                    view.addSubview(button)
                }
            }
        }
    }
    var centerTitleButton: UIButton? {
        didSet {
            //setup
            if var button = centerTitleButton {
                formatTitleButton(&button)
                button.center = CGPoint(x: Int(CGRectGetMidX(view.bounds)), y:  Int(buttonEdge * 0.7))
                button.addTarget(self, action: #selector(POViewController.centerButtonTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                if view.subviews.indexOf(button) == nil {
                    view.addSubview(button)
                }
            }
        }
    }
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.clipsToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = leftTitleButton {
            view.bringSubviewToFront(leftTitleButton!)
        }
        if let _ = rightTitleButton {
            view.bringSubviewToFront(rightTitleButton!)
        }
        if let _ = centerTitleButton {
            view.bringSubviewToFront(centerTitleButton!)
        }
    }
    
    //===================================================================================
    //MARK: Interface
    //===================================================================================
    
    internal func leftButtonTouchUpInside(sender: UIButton) {
        if leftButtonIsBackButton {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    internal func rightButtonTouchUpInside(sender: UIButton) {
        
    }
    
    internal func centerButtonTouchUpInside(sender: UIButton) {
        
    }
    
    private func formatTitleButton(inout button: UIButton) {
        button.bounds = CGRect(x: 0, y: 0, width: buttonEdge, height: buttonEdge)
        button.adjustsImageWhenHighlighted = false
        button.tintColor = UIColor.interfaceColorDark().colorWithAlphaComponent(0.4)
        button.exclusiveTouch = true
        button.addTarget(button, action: #selector(UIView.shrinkForTouchDown), forControlEvents: [.TouchDown, .TouchDragEnter])
        button.addTarget(button, action: #selector(UIView.unshrinkForTouchUp), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchDragExit])
    }
    
    func addDefaultTitleViewWithText(text: String) {
        titleView = UIView(frame: CGRect(x: -CGRectGetWidth(view.bounds) * 0.5, y: 80, width: CGRectGetWidth(view.bounds) * 2.0, height: 80))
        titleView?.userInteractionEnabled = false
        titleView?.backgroundColor = UIColor.interfaceColorDark().colorWithAlphaComponent(0.1)

        let labelView = UILabel(frame: CGRect(x: 0, y: 0, width: CGRectGetWidth(view.bounds) * 0.8, height: 80))
        labelView.center = CGPoint(x: CGRectGetWidth(titleView!.bounds) * 0.5, y: CGRectGetHeight(titleView!.bounds) * 0.5 - 3)
        labelView.text = text
        labelView.textColor = UIColor.interfaceColorDark()
        labelView.textAlignment = .Center
        labelView.font = UIFont.lightAppFontOfSize(40)
        labelView.adjustsFontSizeToFitWidth = true
        titleView?.addSubview(labelView)
    }
    
    func addDefaultBackButton() {
        leftTitleButton = UIButton(type: .Custom)
        if let image = UIImage(named: "back-button") {
            leftTitleButton?.setImage(image.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        }
        leftButtonIsBackButton = true
    }
    
    //===================================================================================
    //MARK: ScrollView Delegate
    //===================================================================================
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        //adjust the titleView scale, translation, and alpha based on scroll contentOffset
        if let _titleView = titleView {
            let maxScroll: CGFloat = 200.0
            
            var normalizedOffset: CGFloat = 0.0
            let adjustedOffset = scrollView.contentOffset.y - scrollViewContentOffsetStart
            if adjustedOffset > 0.0 {
                normalizedOffset = (min(adjustedOffset, maxScroll) / maxScroll)
            }
            else if scrollView.contentOffset.y < 0.0 {
                normalizedOffset = (min(scrollView.contentOffset.y, maxScroll) / maxScroll)
            }
            let easedOffset = pow(max(min(normalizedOffset, 1.0), 0.0), 2)
            let scaleReduction: CGFloat = 0.3
            let alphaReduction: CGFloat = 0.9
            let scale = 1.0 - normalizedOffset * scaleReduction
            let alpha = 1.0 - normalizedOffset * alphaReduction
            
            var transform = CGAffineTransformMakeScale(scale, scale)
            transform = CGAffineTransformTranslate(transform, 0, easedOffset * -40.0)
            
            _titleView.transform = transform
            _titleView.alpha = alpha
        }
    }
}