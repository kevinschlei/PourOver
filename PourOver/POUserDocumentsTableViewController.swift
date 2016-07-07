//
//  PieceTableViewController.swift
//  PourOver
//
//  Created by labuser on 11/5/14.
//  Copyright (c) 2014 labuser. All rights reserved.
//

import UIKit

class POUserDocumentsTableViewController: POPieceTableViewController {
    
    //===================================================================================
    //MARK: Private Properties
    //===================================================================================
    
    override var reminderTextViewText: String {
        get {
            return "No user documents present\n\nCopy your files into iTunes > \(UIDevice.currentDevice().name) > Apps > PourOver > File Sharing\n\n Supported file types: .pd, .aif, .wav, .txt"
        }
    }
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    override func refreshPieces() {
        cellDictionaries.removeAll(keepCapacity: false)
        if let availablePatches = POPdFileLoader.sharedPdFileLoader.availablePatchesInDocuments() {
            cellDictionaries = availablePatches
        }
        //add spacer cells to the top and bottom for correct scrolling behavior
        cellDictionaries.insert(Dictionary(), atIndex: 0)
        cellDictionaries.append(Dictionary())
        
        checkForNoDocuments()
    }
}
