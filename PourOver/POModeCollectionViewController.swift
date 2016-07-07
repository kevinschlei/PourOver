//
//  POModeCollectionViewController.swift
//  PourOver
//
//  Created by kevin on 7/18/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import UIKit

protocol POModeCollectionViewControllerDelegate: class {
    func modeCollectionViewControllerDidSelectActivityType(activityType: POActivityType)
}

class POModeCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    
    private func setupPOModeCollectionViewCell() {
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        imageView.contentMode = .Center
        contentView.addSubview(imageView)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPOModeCollectionViewCell()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupPOModeCollectionViewCell()
    }
}

class POModeCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    weak var delegate: POModeCollectionViewControllerDelegate?

    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = UIColor.interfaceColorLight()
        collectionView?.registerClass(POModeCollectionViewCell.self, forCellWithReuseIdentifier: "POModeCollectionViewCell")
        collectionView?.delaysContentTouches = false
        view.clipsToBounds = true
    }
    
    //===================================================================================
    //MARK: UICollectionViewDelegateFlowLayout
    //===================================================================================
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    //===================================================================================
    //MARK: UICollectionViewDataSource
    //===================================================================================
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return POControllerCoordinator.activityTypes.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("POModeCollectionViewCell", forIndexPath: indexPath) as! POModeCollectionViewCell
        if let imageName = imageNameForActivityType(POControllerCoordinator.activityTypes[indexPath.row]) {
            if let image = UIImage(named:imageName) {
                cell.imageView.image = image.imageWithRenderingMode(.AlwaysTemplate)
                cell.imageView.tintColor = UIColor.interfaceColorDark()
            }
        }
        return cell
    }
    
    //===================================================================================
    //MARK: UICollectionViewDelegate
    //===================================================================================
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.modeCollectionViewControllerDidSelectActivityType(POControllerCoordinator.activityTypes[indexPath.row])
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cellTouchedUp(cell)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cellTouchedDown(cell)
        }
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cellTouchedUp(cell)
        }
    }
    
    func cellTouchedDown(cell: UICollectionViewCell) {
  cell.shrinkForTouchDown()
    }
    
    func cellTouchedUp(cell: UICollectionViewCell) {
  cell.unshrinkForTouchUp()
    }
}
