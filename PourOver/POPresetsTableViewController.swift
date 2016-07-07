//
//  POPresetsTableViewController.swift
//  PourOver
//
//  Created by kevin on 6/19/16.
//  Copyright © 2016 labuser. All rights reserved.
//

import UIKit

class POPresetsTableViewController: POPieceTableViewController {
    
    //===================================================================================
    //MARK: Refresh
    //===================================================================================
    
    override func refreshPieces() {
        cellDictionaries.removeAll(keepCapacity: false)
        
        if let availablePatches = POPdFileLoader.sharedPdFileLoader.availablePresets() {
            cellDictionaries = availablePatches
        }
        
        //add spacer cells to the top and bottom for correct scrolling behavior
        cellDictionaries.insert(Dictionary(), atIndex: 0)
        cellDictionaries.append(Dictionary())
    }

}
