//
//  POHoursMinutesSecondsPickerViewController.swift
//  PourOver
//
//  Created by kevin on 7/13/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import UIKit

protocol POHoursMinutesSecondsPickerViewControllerDelegate: class {
    func hoursMinutesSecondsPickerDidUpdateTime(time: NSTimeInterval, sender: POHoursMinutesSecondsPickerViewController)
}

class POHoursMinutesSecondsPickerViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    weak var delegate: POHoursMinutesSecondsPickerViewControllerDelegate?
    let pickerView = UIPickerView()
    
    let numberFormatter = NSNumberFormatter()
    
    var currentTime: NSTimeInterval = 0
    
    enum TimeDivision: Int {
        case Hours, Minutes, Seconds
    }
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.interfaceColorLight()
            
        pickerView.frame = view.bounds
        pickerView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.tintColor = UIColor.whiteColor()
        view.addSubview(pickerView)
        
        let minutesColonLabel = colonLabel()
        minutesColonLabel.center = CGPoint(x: pickerView.bounds.width * ((1.0 / 6.0) * 4.0), y: pickerView.bounds.midY - 3)
        pickerView.addSubview(minutesColonLabel)
        
        let secondsColonLabel = colonLabel()
        secondsColonLabel.center = CGPoint(x: pickerView.bounds.width * ((1.0 / 6.0) * 2.0), y: pickerView.bounds.midY - 3)
        pickerView.addSubview(secondsColonLabel)
        
        numberFormatter.minimumIntegerDigits = 2
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let hoursIndex = Int(currentTime / 3600)
        let minutesIndex = Int(currentTime / 60)
        let secondsIndex = Int(currentTime % 60)
        pickerView.selectRow(hoursIndex, inComponent: TimeDivision.Hours.rawValue, animated: false)
        pickerView.selectRow(minutesIndex, inComponent: TimeDivision.Minutes.rawValue, animated: false)
        pickerView.selectRow(secondsIndex, inComponent: TimeDivision.Seconds.rawValue, animated: false)
    }
    
    func colonLabel() -> UILabel {
        let colonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        colonLabel.font = UIFont.boldAppFontOfSize(30)
        colonLabel.textAlignment = .Center
        colonLabel.text = ":"
        colonLabel.textColor = UIColor.interfaceColor()
        colonLabel.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        return colonLabel
    }
    
    //===================================================================================
    //MARK: UIPickerViewDataSource
    //===================================================================================

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == TimeDivision.Hours.rawValue) {
            return 24
        }
        else {
            return 60
        }
    }
    
    //===================================================================================
    //MARK: UIPickerViewDelegate
    //===================================================================================
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hours = pickerView.selectedRowInComponent(TimeDivision.Hours.rawValue)
        let minutes = pickerView.selectedRowInComponent(TimeDivision.Minutes.rawValue)
        let seconds = pickerView.selectedRowInComponent(TimeDivision.Seconds.rawValue)
        let time = (hours * 3600) + (minutes * 60) + seconds
        delegate?.hoursMinutesSecondsPickerDidUpdateTime(NSTimeInterval(time), sender: self)
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let componentWidth = pickerView.frame.width / CGFloat(pickerView.numberOfComponents)
        let margin: CGFloat = 0
        let componentLabel = UILabel(frame: CGRect(x: margin, y: 0, width: componentWidth - margin, height: 30.0))
        componentLabel.font = UIFont.lightAppFontOfSize(22)
        if (component == TimeDivision.Seconds.rawValue ||
            component == TimeDivision.Minutes.rawValue) {
            componentLabel.text = numberFormatter.stringFromNumber(NSNumber(integer: row))
        }
        else {
            componentLabel.text = "\(row)"
        }
        componentLabel.textColor = UIColor.interfaceColorDark()
        componentLabel.textAlignment = .Center
        return componentLabel
    }

}
