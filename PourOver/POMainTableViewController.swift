//
//  POMainTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import UIKit

class POMainTableViewController: POTableViewController {
    
    //===================================================================================
    //MARK: Private Properties
    //===================================================================================
    
    private var selectedIndexPath: NSIndexPath?
    
    private lazy var presetTableViewController: POPresetsTableViewController = {
        return POPresetsTableViewController()
    }()
    
    private lazy var userDocumentsTableViewController: POUserDocumentsTableViewController = {
        return POUserDocumentsTableViewController()
    }()
    
    private lazy var googleDriveTableViewController: POGoogleDriveTableViewController = {
        return POGoogleDriveTableViewController()
    }()
    
    private lazy var settingsTableViewController: POSettingsTableViewController = {
        return POSettingsTableViewController()
    }()
    
    private let kPresetsTitle = "Presets"
    private let kUserDocumentsTitle = "User Documents"
    private let kGoogleDriveTitle = "Google Drive"
    private let kSettingsTitle = "Settings"
    
    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollViewContentOffsetStart = 0
        
        let coffeeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        coffeeImageView.image = UIImage(named: "coffee")?.imageWithRenderingMode(.AlwaysTemplate)
        titleView = coffeeImageView
        
        refreshSections()
    }
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    private func refreshDocumentsListAndTableView() {
        //first close the current file
        if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
            appDelegate.controllerCoordinator.stopUpdatingGenerators()
            appDelegate.controllerCoordinator.cleanupGenerators()
            POPdFileLoader.sharedPdFileLoader.closePdFile() {
                //then reload the table
                self.refreshSections()
                self.tableView.reloadData()
                self.presetTableViewController.removeFromParentViewController()
            }
        }
    }
    
    private func refreshSections() {
        cellDictionaries.removeAll(keepCapacity: false)
        
        let presets: [String : AnyObject] = ["title" : kPresetsTitle,
                                             "detailImage" : (UIImage(named: "play-button")?.imageWithRenderingMode(.AlwaysTemplate))!]
        let fileSharing: [String : AnyObject] = ["title" : kUserDocumentsTitle,
                                                 "detailImage" : (UIImage(named: "itunes-icon-fake")?.imageWithRenderingMode(.AlwaysTemplate))!]
        let googleDrive: [String : AnyObject] = ["title" : kGoogleDriveTitle,
                                                 "detailImage" : (UIImage(named: "google-drive-logo-vector")?.imageWithRenderingMode(.AlwaysTemplate))!]
        let settings: [String : AnyObject] = ["title" : kSettingsTitle,
                                              "detailImage" : (UIImage(named: "settings-button-outline")?.imageWithRenderingMode(.AlwaysTemplate))!]
        cellDictionaries.append(presets)
        cellDictionaries.append(fileSharing)
        cellDictionaries.append(googleDrive)
        cellDictionaries.append(settings)
        
        //add spacer cells to the top and bottom for correct scrolling behavior
        cellDictionaries.insert(Dictionary(), atIndex: 0)
        cellDictionaries.append(Dictionary())
    }
    
    //===================================================================================
    //MARK: TableView Data Source
    //===================================================================================
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let pieceTableViewCell = cell as? POTableViewCell {
            pieceTableViewCell.setDetailImage(cellDictionaries[indexPath.row]["detailImage"] as? UIImage)
            return pieceTableViewCell
        }
        else {
            return cell
        }
    }
    
    //===================================================================================
    //MARK: Table View Delegate Methods
    //===================================================================================
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
        if let currentMiddleIndexPath = indexPathForCentermostCellInTableview(tableView) {
            if indexPath == currentMiddleIndexPath {
                //middle cell selected for playback
                //transition to zoomed in, load pd patch, etc.
                
                //insert detail view controller and animate in:
                if let title = cellDictionaries[indexPath.row]["title"] as? String {
                    switch title {
                    case kPresetsTitle:
                        presetTableViewController.title = title
                        navigationController?.pushViewController(presetTableViewController, animated: true)
                    case kUserDocumentsTitle:
                        userDocumentsTableViewController.title = title
                        navigationController?.pushViewController(userDocumentsTableViewController, animated: true)
                    case kGoogleDriveTitle:
                        googleDriveTableViewController.title = title
                        navigationController?.pushViewController(googleDriveTableViewController, animated: true)
                    case kSettingsTitle:
                        settingsTableViewController.title = title
                        navigationController?.pushViewController(settingsTableViewController, animated: true)
                    default:
                        print("no view controller with that title")
                        return
                    }
                }
                
                //store selected indexPath for loading on successful view controller push did finish
                selectedIndexPath = indexPath
            }
        }
        //always deselect
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
