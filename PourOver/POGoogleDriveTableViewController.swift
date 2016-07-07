//
//  POGoogleDriveTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import UIKit

class POGoogleDriveTableViewController: POPieceTableViewController, POGoogleDriveManagerDelegate {
    
    //===================================================================================
    //MARK: Private Properties
    //===================================================================================
    
    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
    private let synchronizingLabel = UILabel()
    private let synchronizingProgressBar = UIProgressView(progressViewStyle: .Bar)
    
    private let driveManager = POGoogleDriveManager()
    
    override var reminderTextViewText: String {
        get {
            return "No documents present\n\nCopy your files into a directory named PourOverApp\n\n Supported file types: .pd, .aif, .wav, .txt"
        }
    }
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        driveManager.authorizationParentViewController = self
        driveManager.delegate = self
        
        synchronizingLabel.text = "Synchronizing..."
        synchronizingLabel.font = UIFont.boldAppFontOfSize(16)
        synchronizingLabel.textColor = UIColor.interfaceColorDark()
        synchronizingLabel.sizeToFit()
        
        centerTitleButton = UIButton(type: .Custom)
        centerTitleButton?.setImage(UIImage(named: "logout-button.png")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setLayoutToSynchronizing()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        driveManager.rescan()
    }
    
    //===================================================================================
    //MARK: Interface
    //===================================================================================
    
    override func rightButtonTouchUpInside(sender: UIButton) {
        driveManager.rescan()
    }
    
    override func centerButtonTouchUpInside(sender: UIButton) {
        let alert = UIAlertController(title: "Log Out?", message: nil, preferredStyle: .Alert)
        let logOutAlertAction = UIAlertAction(title: "Log Out", style: .Default, handler: { action in
            self.driveManager.signOutFromGoogleAccount()
            self.navigationController?.popViewControllerAnimated(true)
        })
        let cancelAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
        })
        alert.addAction(logOutAlertAction)
        alert.addAction(cancelAlertAction)
        presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.interfaceColorLight()
        
    }
    
    //===================================================================================
    //MARK: Layout
    //===================================================================================
    
    private func setLayoutToSynchronizing() {
        rightTitleButton?.userInteractionEnabled = false
        centerTitleButton?.userInteractionEnabled = false
        
        removeNoDocumentsReminders()
        
        tableView.hidden = true
        middleCellHighlightView.hidden = true
        
        if activityIndicatorView.superview == nil {
            view.addSubview(activityIndicatorView)
        }
        if !activityIndicatorView.isAnimating() {
            activityIndicatorView.startAnimating()
        }
        activityIndicatorView.center = CGPoint(x: CGRectGetMidX(view.bounds), y: CGRectGetMidY(view.bounds))
        
        if synchronizingLabel.superview == nil {
            view.addSubview(synchronizingLabel)
        }
        synchronizingLabel.center = CGPoint(x: activityIndicatorView.center.x, y: activityIndicatorView.center.y + 40)
        
        if synchronizingProgressBar.superview == nil {
            view.addSubview(synchronizingProgressBar)
            synchronizingProgressBar.frame = CGRect(x: 0, y: 0, width: 160, height: 20)
            synchronizingProgressBar.center = CGPoint(x: synchronizingLabel.center.x, y: synchronizingLabel.center.y + 40)
            
            synchronizingProgressBar.progress = 0.0
        }
    }
    
    private func setLayoutToFinishedSynchronizing() {
        rightTitleButton?.userInteractionEnabled = true
        centerTitleButton?.userInteractionEnabled = true
        
        tableView.hidden = false
        middleCellHighlightView.hidden = false
        
        activityIndicatorView.stopAnimating()
        activityIndicatorView.removeFromSuperview()
        
        synchronizingLabel.removeFromSuperview()
        synchronizingProgressBar.removeFromSuperview()
    }
    
    private func updateSynchronizingProgressBarPercantage(percentage: Double) {
        synchronizingProgressBar.progress = Float(percentage)
    }
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    override func refreshPieces() {
        cellDictionaries.removeAll(keepCapacity: false)
        
        if let availablePatches = POPdFileLoader.sharedPdFileLoader.availablePatchesInLocalGoogleDriveDirectory() {
            cellDictionaries = availablePatches
        }
        
        //add spacer cells to the top and bottom for correct scrolling behavior
        cellDictionaries.insert(Dictionary(), atIndex: 0)
        cellDictionaries.append(Dictionary())
        
        checkForNoDocuments()
    }
    
    //===================================================================================
    //MARK: POGoogleDriveManagerDelegate
    //===================================================================================
    
    func googleDriveManagerDidChangeStatus(sender: POGoogleDriveManager, status: DriveManagerStatus, message: String) {
        switch status {
        case .Waiting:
            print(message)
        case .Querying:
            setLayoutToSynchronizing()
        case .CannotConnect:
            let alert = UIAlertController(title: "Connection Failed", message: "Rescan?", preferredStyle: .Alert)
            let rescanAlertAction = UIAlertAction(title: "Rescan", style: .Default, handler: { action in
                self.driveManager.rescan()
            })
            let cancelAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
                self.refreshPieces()
                self.tableView.reloadData()
                self.setLayoutToFinishedSynchronizing()
            })
            alert.addAction(rescanAlertAction)
            alert.addAction(cancelAlertAction)
            presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.interfaceColorLight()
        case .FinishedAllFileSync:
            refreshPieces()
            tableView.reloadData()
            setLayoutToFinishedSynchronizing()
        case .FinishedPartialFileSync:
            let alert = UIAlertController(title: "Incomplete Sync", message: "\(message) Rescan?", preferredStyle: .Alert)
            let rescanAlertAction = UIAlertAction(title: "Rescan", style: .Default, handler: { action in
                self.driveManager.rescan()
            })
            let cancelAlertAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
                self.refreshPieces()
                self.tableView.reloadData()
                self.setLayoutToFinishedSynchronizing()
            })
            alert.addAction(rescanAlertAction)
            alert.addAction(cancelAlertAction)
            presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.interfaceColorLight()
        }
    }
    
    func googleDriveManagerDownloadPercentageDidChange(percentage: Double) {
        updateSynchronizingProgressBarPercantage(percentage)
    }
}
