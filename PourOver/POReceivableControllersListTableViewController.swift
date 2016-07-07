//
//  POReceivableControllersListTableViewController.swift
//  PourOver
//
//  Created by kevin on 10/17/15.
//  Copyright © 2015 labuser. All rights reserved.
//

import UIKit

class POReceivableControllersListTableViewController: UITableViewController {
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    var controllersList: [String] = []

    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        tableView.registerClass(POReceivableControllerTableViewCell.self, forCellReuseIdentifier: "POReceivableControllerTableViewCell")
        tableView.backgroundColor = UIColor.highlightColorLight()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? POAppDelegate {
            controllersList = appDelegate.controllerCoordinator.receivableControllersList
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //===================================================================================
    //MARK: TableView Data Source
    //===================================================================================
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return controllersList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("POReceivableControllerTableViewCell", forIndexPath: indexPath) as! POReceivableControllerTableViewCell

        cell.controllerLabel.text = controllersList[indexPath.row]

        return cell
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
