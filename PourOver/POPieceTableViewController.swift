//
//  POPresetTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import UIKit

class POPieceTableViewController: POTableViewController, UINavigationControllerDelegate {
    
    //===================================================================================
    //MARK: Private Properties
    //===================================================================================
    
    private var selectedPieceIndexPath: NSIndexPath?
    private var pieceDetailViewController: POPieceDetailViewController?
    
    internal var reminderTextViewText: String {
        get {
            return ""
        }
    }
    
    lazy internal var reminderTextView: UITextView? = {
        let textView = UITextView(frame: CGRect(x: 10, y: 0, width: CGRectGetWidth(self.view.bounds) - 20, height: 210))
        textView.textAlignment = .Center
        textView.textColor = UIColor.interfaceColorDark()
        textView.backgroundColor = UIColor.clearColor()
        textView.font = UIFont.lightAppFontOfSize(20)
        textView.userInteractionEnabled = false
        return textView
    }()
    
    //===================================================================================
    //MARK: View Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDefaultBackButton()
        if let _ = title {
            addDefaultTitleViewWithText(title!)
        }
        
        rightTitleButton = UIButton(type: .Custom)
        rightTitleButton?.setImage(UIImage(named: "refresh-button.png")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        
        navigationController?.delegate = self
        refreshPieces()
    }
    
    //===================================================================================
    //MARK: Interface
    //===================================================================================
    
    override func rightButtonTouchUpInside(sender: UIButton) {
        closePieceAndRefreshPieceListWithCompletion({
            //then reload the table
            self.refreshPieces()
            self.tableView.reloadData()
            self.pieceDetailViewController?.removeFromParentViewController()
            self.pieceDetailViewController = nil
        })
    }
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    internal func closePieceAndRefreshPieceListWithCompletion(completion: (() -> ())?) {
        //first close the current file
        if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
            appDelegate.controllerCoordinator.stopUpdatingGenerators()
            appDelegate.controllerCoordinator.cleanupGenerators()
            POPdFileLoader.sharedPdFileLoader.closePdFile() {
                completion?()
            }
        }
    }
    
    internal func refreshPieces() {
        //implemented by children to refresh cellDictionaries
    }
    
    internal func checkForNoDocuments() {
        if cellDictionaries.count <= 2 {
            middleCellHighlightView.hidden = true
            addNoDocumentsReminders()
        }
        else {
            middleCellHighlightView.hidden = false
            removeNoDocumentsReminders()
        }
    }
    
    //===================================================================================
    //MARK: Table View Delegate Methods
    //===================================================================================
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        
        if let currentMiddleIndexPath = self.indexPathForCentermostCellInTableview(tableView) {
            if indexPath == currentMiddleIndexPath {
                //middle cell selected for playback
                //transition to zoomed in, load pd patch, etc.
                
                //insert detail view controller and animate in:
                if pieceDetailViewController?.title != cellDictionaries[indexPath.row]["title"] as? String {
                    if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
                        appDelegate.controllerCoordinator.stopUpdatingGenerators()
                        appDelegate.controllerCoordinator.cleanupGenerators()
                        POPdFileLoader.sharedPdFileLoader.closePdFile() {
                            //instantiate pieceDetailViewController and push it onto the navigation controller stack
                            //once the transition is complete, the UINavigationController delegate method didShowViewController:animated: will load the Pd patch
                            self.pieceDetailViewController = nil
                            self.pieceDetailViewController = POPieceDetailViewController()
                            self.pieceDetailViewController!.pieceTitle = self.cellDictionaries[indexPath.row]["title"] as? String
                            
                            if let defaultLength = self.cellDictionaries[indexPath.row]["defaultLength"] as? Double {
                                self.pieceDetailViewController!.defaultLength = NSTimeInterval(Int(defaultLength))
                            }
                            
                            //store selected indexPath for loading on successful view controller push did finish
                            self.selectedPieceIndexPath = indexPath
                            self.navigationController?.pushViewController(self.pieceDetailViewController!, animated: true)
                        }
                    }
                }
                else {
                    //do not re-load the patch
                    selectedPieceIndexPath = nil
                    navigationController?.pushViewController(pieceDetailViewController!, animated: true)
                }
            }
        }
        //always deselect
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //===================================================================================
    //MARK: Layout
    //===================================================================================
    
    internal func addNoDocumentsReminders() {
        if reminderTextView?.superview == nil {
            reminderTextView?.text = reminderTextViewText
            reminderTextView?.sizeToFit()
            reminderTextView?.center = CGPoint(x: CGRectGetWidth(view.bounds) / 2.0, y: CGRectGetHeight(view.bounds) / 2.0)
            if let _ = reminderTextView {
                view.addSubview(reminderTextView!)
            }
        }
    }
    
    internal func removeNoDocumentsReminders() {
        reminderTextView?.removeFromSuperview()
    }
    
    //===================================================================================
    //MARK: UINavigationControllerDelegate
    //===================================================================================
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if viewController is POPieceDetailViewController {
            //load selected file
            if let indexPath = selectedPieceIndexPath {
                if let filePath = cellDictionaries[indexPath.row]["filePath"] as? String {
                    let success = POPdFileLoader.sharedPdFileLoader.loadPdFileAtPath(filePath)
                    if !success {
                        return
                    }
                }
            }
        }
    }
}
