//
//  POReceivableControllerTableViewCell.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

class POReceivableControllerTableViewCell: UITableViewCell {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    let controllerLabel = UILabel()
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    private func setupPieceTableViewCell() {
        
        //title label, goes in contentView
        controllerLabel.textColor = UIColor.interfaceColorDark()
        controllerLabel.textAlignment = .Left
        controllerLabel.font = UIFont.boldAppFontOfSize(16)
        controllerLabel.bounds = CGRect(x: 0, y: 0, width: contentView.bounds.width * 0.95, height: kPieceTableViewCellHeight / 3.0)
        controllerLabel.center = contentView.bounds.boundsCenter()
        controllerLabel.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        contentView.addSubview(controllerLabel)
        
        //colors
        contentView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        //highlight color
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.clearColor()
        selectedBackgroundView = highlightView
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupPieceTableViewCell()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupPieceTableViewCell()
    }
    
}