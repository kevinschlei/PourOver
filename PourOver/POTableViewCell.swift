//
//  PieceTableViewCell.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

class POTableViewCell: UITableViewCell {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    let titleLabel = UILabel()
    let descriptionLabel = UILabel()
    let revealView = UIView()
    
    lazy var detailImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        imageView.center = CGPoint(x: self.contentView.center.x, y: CGRectGetHeight(self.contentView.bounds) - 35)
        self.revealView.addSubview(imageView)
        return imageView
    }()
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    private func setupPieceTableViewCell() {
        //the moving mask view
        //anything in this view will only appear when the cell is in the middle of the PieceTableView
        revealView.frame = contentView.bounds
        revealView.clipsToBounds = true
        revealView.autoresizingMask = .FlexibleWidth
        contentView.addSubview(revealView)
        
        //description label, goes in reveal view
        descriptionLabel.frame = CGRect(x: 8, y: kPieceTableViewCellHeight / 3.0, width: contentView.bounds.width - 16, height: kPieceTableViewCellHeight - kPieceTableViewCellHeight / 3.0)
        descriptionLabel.textColor = UIColor.interfaceColorDark()
        descriptionLabel.font = UIFont.lightAppFontOfSize(16)
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textAlignment = .Center
        descriptionLabel.autoresizingMask = .FlexibleWidth
        descriptionLabel.alpha = 0.5
        revealView.addSubview(descriptionLabel)
        
        //title label, goes in contentView
        titleLabel.textColor = UIColor.interfaceColorDark()
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.boldAppFontOfSize(22)
        titleLabel.bounds = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: kPieceTableViewCellHeight / 2.6)
        titleLabel.center = CGPoint(x: CGRectGetWidth(contentView.bounds) / 2.0, y: CGRectGetHeight(titleLabel.bounds) / 2.0 + 4)
        titleLabel.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        contentView.addSubview(titleLabel)
        
//        for subview in contentView.subviews {
//            subview.showBorder()
//        }
        
        //colors
        contentView.backgroundColor = UIColor.clearColor()
        backgroundColor = UIColor.clearColor()
        
        //highlight color
        let highlightView = UIView()
        //        highlightView.backgroundColor = UIColor.highlightColorLight()
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
    
    //===================================================================================
    //MARK: Cell Content
    //===================================================================================
    
    func setTitle(title: String) {
        titleLabel.text = title
    }
    
    func setDescription(description: String) {
        descriptionLabel.text = description
    }
    
    func setDetailImage(image: UIImage?) {
        detailImageView.image = image
    }
    
    //===================================================================================
    //MARK: Interface
    //===================================================================================
    
    /**
    Notification method of scroll position change to resize revealView. 'distance' should not be an absolute value.
    */
    func distanceToTableViewCenterDidChange(distance: CGFloat) {
        if abs(distance) > contentView.bounds.height {
            revealView.hidden = true
        }
        else if distance <= 0 {
            revealView.hidden = false
            revealView.frame = CGRect(x: 0, y: abs(distance), width: contentView.bounds.width, height: contentView.bounds.height - abs(distance))
            for subview in revealView.subviews as [UIView] {
                subview.transform = CGAffineTransformMakeTranslation(0, distance)
            }
        }
        else {
            revealView.hidden = false
            revealView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - distance)
            for subview in revealView.subviews as [UIView] {
                subview.transform = CGAffineTransformIdentity
            }
        }
    }
    
}
