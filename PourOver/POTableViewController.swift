//
//  POTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

//
//  PieceTableViewController.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

let kPieceTableViewCellHeight: CGFloat = 100

class POTableViewController: POViewController, UITableViewDataSource, UITableViewDelegate {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    /**
     Array of Dictionaries representing .pd files scanned from the Documents directory.
     "title" : String
     "description" : String
     "filePath" : String
     and possibly:
     "defaultLength" : String
     */
    internal var cellDictionaries: [[String : AnyObject]] = []
    
    internal let middleCellHighlightView = UIView()
    internal let tableView = UITableView()
    
    private var spacerHeight: CGFloat = 0
    
    private var selectedPieceIndexPath: NSIndexPath?
    
    //===================================================================================
    //MARK: View Lifecycle
    //===================================================================================
    
    private func setupPieceTableViewController() {
        self.title = " " //single space for no 'Back' on pushed view controller back button
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setupPieceTableViewController()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setupPieceTableViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = UIColor.appBackgroundColor()
        
        //push the navigation bar off screen
        if let navBar = navigationController?.navigationBar {
            //if we'd rather avoid seeing the navbar entirely (we keep for free swipe-to-go-back gesture)
            let offsetY = CGRectGetHeight(navBar.bounds)
            navBar.transform = CGAffineTransformMakeTranslation(0, -offsetY)
            
            navBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            navBar.shadowImage = UIImage()
            navBar.translucent = true
            navBar.userInteractionEnabled = false
            navigationController?.view.backgroundColor = UIColor.clearColor()
        }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor.highlightColorLight().CGColor, UIColor.appBackgroundColor().CGColor, UIColor.highlightColorLight().CGColor]
        view.layer.addSublayer(gradientLayer)
        
        //save view background gradient as PNG
        view.saveAsPNGToFile(kDocumentsPath.stringByAppendingString("/gradient-background.png"))
        
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(POTableViewCell.self, forCellReuseIdentifier: "POTableViewCell")
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "EmptyTableViewCell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.clearColor()
        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        
        middleCellHighlightView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: kPieceTableViewCellHeight)
        middleCellHighlightView.center = view.center
        middleCellHighlightView.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin, .FlexibleBottomMargin]
        middleCellHighlightView.backgroundColor = UIColor.highlightColorLight()
        view.insertSubview(middleCellHighlightView, belowSubview: tableView)
        
        //the height for the single spacer cell at the beginning and end of the tableView
        spacerHeight = (view.bounds.height - middleCellHighlightView.bounds.height) / 2.0
                
        //        let gradient = PODefaultBackgroundGradientView(frame: view.bounds)
        //        view.addSubview(gradient)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.scrollToMiddlemostCell(animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.scrollViewDidScroll(tableView)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //===================================================================================
    //MARK: Table View Data Source
    //===================================================================================
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 || indexPath.row == cellDictionaries.count - 1 {
            return self.spacerHeight
        }
        else {
            return kPieceTableViewCellHeight
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDictionaries.count //includes both spacer cells
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if cellAtIndexIsSpacerCell(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier("EmptyTableViewCell", forIndexPath: indexPath) as UITableViewCell
            cell.contentView.backgroundColor = UIColor.clearColor()
            cell.backgroundColor = UIColor.clearColor()
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("POTableViewCell", forIndexPath: indexPath) as! POTableViewCell
            if let title = cellDictionaries[indexPath.row]["title"] as? String {
                cell.setTitle(title)
            }
            if let description = cellDictionaries[indexPath.row]["description"] as? String {
                cell.setDescription(description)
            }
            self.updateCellHiddenContent(cell)
            return cell as UITableViewCell
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.shrinkALittleForTouchDown()
        }
        return !cellAtIndexIsSpacerCell(indexPath)
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.unshrinkForTouchUp()
        }
    }
    
    func cellAtIndexIsSpacerCell(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == 0 || indexPath.row == cellDictionaries.count - 1
    }
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    func refreshButtonPressed(sender: UIButton) {
    }
    
    //===================================================================================
    //MARK: Table View Delegate Methods
    //===================================================================================
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let currentMiddleIndexPath = self.indexPathForCentermostCellInTableview(tableView) {
            if indexPath == currentMiddleIndexPath {
                //middle cell selected for playback
                //transition to zoomed in, load pd patch, etc.
                
                //you can tap the middle cell while it's in the middle of scrolling, this animates just in case
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: false)
            }
            else {
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
            }
        }
        //always deselect
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //===================================================================================
    //MARK: Scroll View Delegate Methods
    //===================================================================================
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        for cell in tableView.visibleCells {
            if let pieceCell = cell as? POTableViewCell {
                self.updateCellHiddenContent(pieceCell)
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.scrollToMiddlemostCell(animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= 0 &&
            !scrollView.tracking {
            self.scrollToMiddlemostCell(animated: true)
        }
    }
    
    func scrollToMiddlemostCell(animated animated: Bool) {
        if let indexPath = self.indexPathForCentermostCellInTableview(tableView) {
            var middleIndexPath = indexPath
            if indexPath.row == 0 {
                middleIndexPath = NSIndexPath(forRow: 1, inSection: middleIndexPath.section)
            }
            else if indexPath.row == cellDictionaries.count - 1 {
                middleIndexPath = NSIndexPath(forRow: cellDictionaries.count - 2, inSection: middleIndexPath.section)
            }
            tableView.scrollToRowAtIndexPath(middleIndexPath, atScrollPosition: .Middle, animated: animated)
        }
    }
    
    //===================================================================================
    //MARK: Cell Interface
    //===================================================================================
        
    internal func indexPathForCentermostCellInTableview(tableView: UITableView) -> NSIndexPath? {
        if self.tableView(tableView, numberOfRowsInSection: 0) <= 2 {
            return nil
        }
        let viewCenter = tableView.bounds.boundsCenter()
        var closestCell: UITableViewCell? = nil
        var closestDistanceToCenter = CGFloat(NSIntegerMax)
        for cell in tableView.visibleCells {
            //account for contentOffset
            let cellCenterInView = cell.center - tableView.contentOffset
            let cellDistanceToCenter = cellCenterInView.distanceToPoint(viewCenter)
            if cellDistanceToCenter < closestDistanceToCenter {
                closestDistanceToCenter = cellDistanceToCenter
                closestCell = cell
            }
        }
        if closestCell != nil {
            return tableView.indexPathForCell(closestCell!)
        }
        else {
            return nil
        }
    }
    
    private func updateCellHiddenContent(cell: POTableViewCell) {
        let viewCenter = tableView.bounds.boundsCenter()
        let cellCenterInView = cell.center - tableView.contentOffset
        let cellDeltaYToCenter = cellCenterInView.y - viewCenter.y
        cell.contentView.alpha = (viewCenter.y - abs(cellDeltaYToCenter / 2.0)) / viewCenter.y
        cell.distanceToTableViewCenterDidChange(cellDeltaYToCenter)
    }
    
    private func tableViewContentCenter(tableView: UITableView) -> CGPoint {
        return CGPoint(x: tableView.contentSize.width / 2.0, y: (tableView.bounds.height / 2.0) + tableView.contentOffset.y)
    }
    
    //===================================================================================
    //MARK: Rotation
    //===================================================================================
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ context in
            self.scrollToMiddlemostCell(animated: false)
            }, completion: nil)
    }
    
}
