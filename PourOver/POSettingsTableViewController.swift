//
//  POSettingsTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/21/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import UIKit

class POSettingsTableViewController: POViewController, UITableViewDataSource, UITableViewDelegate {
    
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
    
    internal let tableView = UITableView()
    
    //===================================================================================
    //MARK: View Lifecycle
    //===================================================================================
    
    private func setupSettingsTableViewController() {
        title = " " //single space for no 'Back' on pushed view controller back button
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupSettingsTableViewController()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupSettingsTableViewController()
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
        
        addDefaultBackButton()
        if let _ = title {
            addDefaultTitleViewWithText(title!)
        }
        
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(POTableViewCell.self, forCellReuseIdentifier: "POTableViewCell")
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "EmptyTableViewCell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.clearColor()
        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.delaysContentTouches = false
        
        if let _ = titleView {
            //inset
            let bottomOfTitleView = CGRectGetMaxY(titleView!.frame)
            tableView.contentInset = UIEdgeInsets(top: bottomOfTitleView + 60, left: 0, bottom: 0, right: 0)
        }
        
        view.addSubview(tableView)
        
        cellDictionaries = [
            ["title" : "There"],
            ["title" : "are"],
            ["title" : "no"],
            ["title" : "settings."]
        ];
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //===================================================================================
    //MARK: Table View Data Source
    //===================================================================================
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDictionaries.count //includes both spacer cells
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("POTableViewCell", forIndexPath: indexPath) as! POTableViewCell
        
        cell.backgroundColor = UIColor.interfaceColorMedium().colorWithAlphaComponent(0.1)
        cell.titleLabel.textAlignment = .Left
        
        if let title = cellDictionaries[indexPath.row]["title"] as? String {
            cell.setTitle(title)
        }
        if let description = cellDictionaries[indexPath.row]["description"] as? String {
            cell.setDescription(description)
        }
        return cell as UITableViewCell
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.shrinkALittleForTouchDown()
        }
        return true
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.unshrinkForTouchUp()
        }
    }
    
    //===================================================================================
    //MARK: Table View Delegate Methods
    //===================================================================================
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        //always deselect
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}
