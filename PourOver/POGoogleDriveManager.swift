//
//  POGoogleDriveManager.swift
//  pogdtest
//
//  Created by kevin on 6/18/16.
//  Copyright © 2016 PSOA Music. All rights reserved.
//

import Foundation
import GoogleAPIClient
import GTMOAuth2

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//MARK: Globals (belonging somewhere else?)
//_______________________________________________________________________________________

let kDocumentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
let kLocalPourOverAppDirectoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0].stringByAppendingString("/PourOverApp")
let kLocalPourOverAppDirectoryURL = NSURL(fileURLWithPath: kLocalPourOverAppDirectoryPath)

enum DriveManagerStatus {
    case Waiting
    case CannotConnect
    case Querying
    case FinishedAllFileSync
    case FinishedPartialFileSync
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//MARK: POGoogleDriveManagerDelegate
//_______________________________________________________________________________________

protocol POGoogleDriveManagerDelegate: class {
    func googleDriveManagerDidChangeStatus(sender: POGoogleDriveManager, status: DriveManagerStatus, message: String)
    func googleDriveManagerDownloadPercentageDidChange(percentage: Double)
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//MARK: POGoogleDriveManager
//_______________________________________________________________________________________

class POGoogleDriveManager: NSObject {
    
    //===================================================================================
    //MARK: Public Properties
    //===================================================================================
    
    weak var delegate: POGoogleDriveManagerDelegate?
    weak var authorizationParentViewController: UIViewController?
    
    //===================================================================================
    //MARK: Private Properties
    //===================================================================================
    
    private let kKeychainItemName = "Drive API"
    private let kClientID = "133846225343-0t8if8o8p7ffc8vj7mb76feiji8qctbp.apps.googleusercontent.com"
    
    //if modifying these scopes, delete your previously saved credentials by resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeDriveReadonly]
    private let service = GTLServiceDrive()

    private var pourOverAppDirectory: GTLDriveFile?
    
    private var allDirectories: [GTLDriveFile]?
    private var allDirectoryDictionaries: [[String : AnyObject]]?
    private var pourOverAppDirectoryDictionaries: [[String : AnyObject]]?
    
    private var allFiles: [GTLDriveFile]?
    private var pourOverAppFileDictionaries: [[String : AnyObject]]?
    
    private var iteratingDirectoryURL = NSURL()
    
    private var statusText: String?
    private var indentCount = 0
    
    private var filesToDownloadCount = 0 {
        didSet {
            if filesToDownloadCount > 0 {
                delegate?.googleDriveManagerDownloadPercentageDidChange(Double(filesActuallyDownloadedCount) / Double(filesToDownloadCount))
            }
        }
    }
    private var filesActuallyDownloadedCount = 0 {
        didSet {
            if filesToDownloadCount > 0 {
                delegate?.googleDriveManagerDownloadPercentageDidChange(Double(filesActuallyDownloadedCount) / Double(filesToDownloadCount))
            }
        }
    }
    private var fileDownloadAttempts = 0

    //===================================================================================
    //MARK: Lifecycle
    //===================================================================================
    
    override init() {
        super.init()
        
        //ensure we have a local 'PourOverApp' directory
        if !NSFileManager.defaultManager().fileExistsAtPath(kLocalPourOverAppDirectoryPath) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(kLocalPourOverAppDirectoryPath, withIntermediateDirectories: false, attributes: [:])
            }
            catch let error {
                print("error creating kLocalPourOverAppDirectoryPath \(error)")
            }
        }
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName (
            kKeychainItemName,
            clientID: kClientID,
            clientSecret: nil) {
            service.authorizer = auth
        }
    }
    
    //===================================================================================
    //MARK: Rescan
    //===================================================================================
    
    func rescan() {
        if let authorizer = service.authorizer,
            canAuth = authorizer.canAuthorize where canAuth {
            
            //clear out properties
            clearStores()
            
            //begin file fetch
            fetchpourOverAppDirectory(pageToken: nil)
        }
        else {
            authorizationParentViewController?.presentViewController(
                createAuthController(),
                animated: true,
                completion: nil
            )
        }
    }
    
    private func clearStores() {
        //nil out pourover directory (will check for it now)
        pourOverAppDirectory = nil
        
        allDirectories = []
        allDirectoryDictionaries = []
        allFiles = []
        pourOverAppFileDictionaries = []
        pourOverAppDirectoryDictionaries = []
        
        filesToDownloadCount = 0
        filesActuallyDownloadedCount = 0
        fileDownloadAttempts = 0
    }
    
    private func finishRescan() {
        if filesActuallyDownloadedCount == filesToDownloadCount {
            delegate?.googleDriveManagerDidChangeStatus(self, status: .FinishedAllFileSync, message: statusText!)
        }
        else {
            let message = "\(filesToDownloadCount - filesActuallyDownloadedCount) files failed to download."
            delegate?.googleDriveManagerDidChangeStatus(self, status: .FinishedPartialFileSync, message: message)
        }
        
        clearStores()
    }
    
    //===================================================================================
    //MARK: Sign Out
    //===================================================================================
    
    func signOutFromGoogleAccount() {
        if let authorizer = service.authorizer as? GTMOAuth2Authentication {
            GTMOAuth2SignIn.revokeTokenForGoogleAuthentication(authorizer)
        }
    }
    
    //===================================================================================
    //MARK: File Metadata Fetching
    //===================================================================================
    
    private func fetchpourOverAppDirectory(pageToken nextPageToken: String?) {
        delegate?.googleDriveManagerDidChangeStatus(self, status: .Querying, message: "Getting files...")

        let query = GTLQueryDrive.queryForFilesList()
        query.pageSize = 100
        query.pageToken = nextPageToken
        query.fields = "nextPageToken, files(id, parents, sharingUser, name, mimeType)"
        
        //filter for PourOver directory
        query.q = "name='PourOverApp' and mimeType='application/vnd.google-apps.folder'"
        
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: #selector(POGoogleDriveManager.fetchpourOverAppDirectoryDidReturnWithTicket(_:finishedWithObject:error:))
        )
    }
    
    internal func fetchpourOverAppDirectoryDidReturnWithTicket(ticket: GTLServiceTicket, finishedWithObject response: GTLDriveFileList, error: NSError?) {
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        if let files = response.files where !files.isEmpty {
            for file in files as! [GTLDriveFile] {
                if file.name == "PourOverApp" {
                    pourOverAppDirectory = file
                }
            }
        }
        
        if response.nextPageToken != nil {
            fetchpourOverAppDirectory(pageToken: response.nextPageToken)
        }
        else {
            //done iterating
            if pourOverAppDirectory == nil {
                //no pourover directory found
                let alert = UIAlertController(title: "Directory Not Found", message: "Add a directory named 'PourOverApp' to your Google Drive", preferredStyle: UIAlertControllerStyle.Alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
                    // ...
                }
                alert.addAction(cancelAction)
                authorizationParentViewController?.presentViewController(alert, animated: true, completion: nil)
            }
            else {
                //continue with directory search
                fetchAllDirectories(pageToken: nil)
            }
        }
    }
    
    private func fetchAllDirectories(pageToken nextPageToken: String?) {
        delegate?.googleDriveManagerDidChangeStatus(self, status: .Querying, message: "Getting files...")
        
        let query = GTLQueryDrive.queryForFilesList()
        query.pageSize = 100
        query.pageToken = nextPageToken
        query.fields = "nextPageToken, files(id, parents, sharingUser, name, mimeType)"
        
        //filter for PourOver directory
        query.q = "mimeType='application/vnd.google-apps.folder'"
        
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: #selector(POGoogleDriveManager.fetchAllDirectoriesDidReturnWithTicket(_:finishedWithObject:error:))
        )
    }
    
    internal func fetchAllDirectoriesDidReturnWithTicket(ticket : GTLServiceTicket, finishedWithObject response : GTLDriveFileList, error : NSError?) {
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        if let files = response.files where !files.isEmpty {
            for file in files as! [GTLDriveFile] {
                allDirectories?.append(file)
            }
        }
        
        if response.nextPageToken != nil {
            fetchAllDirectories(pageToken: response.nextPageToken)
        }
        else {
            fetchFiles(pageToken: nil)
        }
    }
    
    private func fetchFiles(pageToken nextPageToken: String?) {
        delegate?.googleDriveManagerDidChangeStatus(self, status: .Querying, message: "Getting files...")

        let query = GTLQueryDrive.queryForFilesList()
        query.pageSize = 100
        query.pageToken = nextPageToken
        query.fields = "nextPageToken, files(id, parents, mimeType, sharingUser, modifiedTime, name)"
        
        /*
         filter to:
         .pd
         .wav
         .aif
         .txt
         folder
         */
        query.q = "mimeType='application/octet-stream' or mimeType='audio/x-wav' or mimeType='audio/x-aiff' or mimeType='text/plain' or mimeType='application/vnd.google-apps.folder'"
        
        service.executeQuery(
            query,
            delegate: self,
            didFinishSelector: #selector(POGoogleDriveManager.fetchFilesDidReturnWithTicket(_:finishedWithObject:error:))
        )
    }
    
    internal func fetchFilesDidReturnWithTicket(ticket : GTLServiceTicket, finishedWithObject response : GTLDriveFileList, error : NSError?) {
        if let error = error {
            showAlert("Error", message: error.localizedDescription)
            return
        }
        
        if statusText == nil {
            statusText = ""
        }
        
        var filesString = ""
        
        var pdFileContainingDirectoryIDs: Set<String> = []
        
        if let files = response.files where !files.isEmpty {
            for file in files as! [GTLDriveFile] {
                allFiles?.append(file)
                
                filesString += "\(file.name) (\(file.parents))\n"
                if file.mimeType == "application/octet-stream" &&
                    file.name.containsString(".pd") {
                    for parent in file.parents {
                        if let id = parent as? String {
                            pdFileContainingDirectoryIDs.insert(id)
                        }
                    }
                }
            }
        }
        else {
            filesString = "No files found."
        }
        
        statusText! += filesString
        
        if let nextPageToken = response.nextPageToken {
            //continue scanning
            print("nextPageToken \(nextPageToken)")
            fetchFiles(pageToken: nextPageToken)
        }
        else {
            //finished all files scan, copy into place locally:
            buildPourOverAppDirectoryHierarchy()
        }
    }
    
    //===================================================================================
    //MARK: Building Local File Hierarchy
    //===================================================================================
    
    private func buildDirectoryChildren() {
        if let directories = allDirectories {
            //add the directory to the list
            for directory in directories {
                allDirectoryDictionaries!.append(["file" : directory,
                    "children" : [GTLDriveFile]()])
            }
            
            //add them to the children array of their parent directory
            for directory in allDirectoryDictionaries! {
                if let parents = directory["file"]?.parents as? [String] {
                    for parent in parents {
                        for i in 0..<allDirectoryDictionaries!.count {
                            if let identifier = allDirectoryDictionaries![i]["file"]?.identifier {
                                if parent == identifier {
                                    if var children = allDirectoryDictionaries![i]["children"]?.mutableCopy() as? [GTLDriveFile] {
                                        children.append(directory["file"] as! GTLDriveFile)
                                        allDirectoryDictionaries![i]["children"] = children
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        buildPourOverAppDirectories()
        
        //start pourOverAppFileDictionaries off with the contents of allDirectoryDictionaries
        for d in allDirectoryDictionaries! {
            pourOverAppFileDictionaries?.append(d)
        }
    }
    
    private func buildPourOverAppDirectories() {
        addDirectoryAndChildrenToPourOverAppDirectories(pourOverAppDirectory!)
    }
    
    private func addDirectoryAndChildrenToPourOverAppDirectories(directory: GTLDriveFile) {
        for i in 0..<allDirectoryDictionaries!.count {
            if allDirectoryDictionaries![i]["file"] as? GTLDriveFile == directory {
                pourOverAppDirectoryDictionaries?.append(allDirectoryDictionaries![i])
                
                //iterate through children
                if let children = allDirectoryDictionaries![i]["children"] as? [GTLDriveFile] {
                    for child in children {
                        addDirectoryAndChildrenToPourOverAppDirectories(child)
                    }
                }
            }
        }
    }
    
    private func addChildFilesToDirectory(directory: GTLDriveFile) {
        for i in 0..<pourOverAppFileDictionaries!.count {
            if pourOverAppFileDictionaries![i]["file"] as? GTLDriveFile == directory {
                //add any files that match this directory as a parent
                if let files = allFiles {
                    for file in files {
                        for parent in file.parents {
                            if let id = parent as? String {
                                if id == directory.identifier {
                                    if file.mimeType != "application/vnd.google-apps.folder" {
                                        if var children = pourOverAppFileDictionaries![i]["children"]?.mutableCopy() as? [GTLDriveFile] {
                                            if children.indexOf(file) == nil {
                                                children.append(file)
                                                pourOverAppFileDictionaries![i]["children"] = children
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                //iterate through children
                if let children = pourOverAppFileDictionaries![i]["children"] as? [GTLDriveFile] {
                    for child in children {
                        addChildFilesToDirectory(child)
                    }
                }
            }
        }
    }
    
    private func printChildren(directory: GTLDriveFile, inout toString string: String) {
        indentCount += 1
        for d in pourOverAppFileDictionaries! {
            if d["file"] as? GTLDriveFile == directory {
                //do the thing you want to do
                var indent = ""
                for _ in 0..<indentCount {
                    indent += "    "
                }
                //iterate through children
                if let children = d["children"] as? [GTLDriveFile] {
                    for child in children {
                        let childString = indent + child.name
                        string += childString + "\n"
                        printChildren(child, toString: &string)
                    }
                }
            }
        }
        indentCount -= 1
    }
    
    private func buildPourOverAppDirectoryHierarchy() {
        buildDirectoryChildren()
        addChildFilesToDirectory(pourOverAppDirectory!)

        var printString = ""
        printChildren(pourOverAppDirectory!, toString: &printString)
        print(printString)
        
        synchronizeLocalCopies()
        
        if filesToDownloadCount == 0 {
            finishRescan()
        }
    }
    
    //===================================================================================
    //MARK: File Synchronization
    //===================================================================================
    
    private func synchronizeLocalCopies() {
        let fileManager = NSFileManager.defaultManager()
        
        //create local 'PourOverApp' directory if it does not exist
        if !fileManager.fileExistsAtPath(kLocalPourOverAppDirectoryPath) {
            do {
                try fileManager.createDirectoryAtURL(kLocalPourOverAppDirectoryURL, withIntermediateDirectories: true, attributes: [:])
            }
            catch let error {
                print("error creating local pouroverapp directory \(error)")
            }
        }
        
        //before iterating, clear iteratingDirectoryURL by setting it to the local PourOverApp directory's parent
        iteratingDirectoryURL = kLocalPourOverAppDirectoryURL.URLByDeletingLastPathComponent!
        
        //compare
        if let p = pourOverAppDirectory {
            synchronizeChildrenInDirectory(p)
        }
        
        //remove any local files / directories that are not present in the Drive directory
    }
    
    private func synchronizeChildrenInDirectory(directory: GTLDriveFile) {
        for i in 0..<pourOverAppFileDictionaries!.count {
            if pourOverAppFileDictionaries![i]["file"] as? GTLDriveFile == directory {
                iteratingDirectoryURL = iteratingDirectoryURL.URLByAppendingPathComponent(directory.name!)
                
                //get any existing local file urls in a mutable array
                var localFilesToDelete: [String]?
                do {
                    localFilesToDelete = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(iteratingDirectoryURL.path!)
                }
                catch let error {
                    print("error getting contentsOfDirectoryAtPath \(error)")
                }
                
                //iterate through children
                if let children = pourOverAppFileDictionaries![i]["children"] as? [GTLDriveFile] {
                    for child in children {
                        //sync the file
                        let localFileURL = iteratingDirectoryURL.URLByAppendingPathComponent(child.name!)
                        synchronizeLocalFileAtURL(localFileURL, withDriveFile: child)
                        
                        //taken care of a local file, remove from files-to-delete
                        if let index = localFilesToDelete?.indexOf(child.name!) {
                            localFilesToDelete?.removeAtIndex(index)
                        }
                        
                        //if it's a directory, sync its children
                        if child.mimeType == "application/vnd.google-apps.folder" {
                            synchronizeChildrenInDirectory(child)
                        }
                    }
                }
                
                //delete any local files / directories that no longer appear on Drive
                if let filesToDelete = localFilesToDelete {
                    for fileName in filesToDelete {
                        let fileURL = iteratingDirectoryURL.URLByAppendingPathComponent(fileName)
                        do {
                            try NSFileManager.defaultManager().removeItemAtURL(fileURL)
                        }
                        catch {
                            print("error removing at url \(fileURL) \(error)")
                        }
                    }
                }
            }
        }
        
        iteratingDirectoryURL = iteratingDirectoryURL.URLByDeletingLastPathComponent!
    }
    
    private func synchronizeLocalFileAtURL(localFileURL: NSURL, withDriveFile driveFile: GTLDriveFile) {
        //print("sync \(driveFile.name!)")
        
        let fileManager = NSFileManager.defaultManager()
        
        //check if it's a directory, create if necessary
        if driveFile.mimeType == "application/vnd.google-apps.folder" {
            var createDirectory = false
            
            //directory / file already exists?
            var isDirectory: ObjCBool = false
            let fileExistsAtPath = fileManager.fileExistsAtPath(localFileURL.path!, isDirectory: &isDirectory)
            if fileExistsAtPath {
                createDirectory = !isDirectory
            }
            else {
                createDirectory = true
            }
            
            //create if necessary
            if createDirectory {
                do {
                    try fileManager.createDirectoryAtURL(localFileURL, withIntermediateDirectories: true, attributes: [:])
                }
                catch let error {
                    print("error creating directory at \(localFileURL) \(error)")
                }
            }
        }
        else {
            //compare local file, then download
            let fileExistsAtPath = fileManager.fileExistsAtPath(localFileURL.path!)
            
            //if no local file is present, download it
            if !fileExistsAtPath {
                filesToDownloadCount += 1
                downloadFile(driveFile, toURL: localFileURL)
            }
            else {
                //get the modification date
                do {
                    let attributes = try fileManager.attributesOfItemAtPath(localFileURL.path!)
                    if let date = attributes[NSFileModificationDate] {
                        if date.compare(driveFile.modifiedTime!.date) == .OrderedAscending {
                            //drive file is newer, download it
                            filesToDownloadCount += 1
                            downloadFile(driveFile, toURL: localFileURL)
                        }
                    }
                    
                }
                catch let error {
                    print("error getting local file attributes at url \(localFileURL) \(error)")
                }
            }
        }
    }
    
    //===================================================================================
    //MARK: File Downloading
    //===================================================================================
    
    private func downloadFile(file: GTLDriveFile, toURL targetURL: NSURL) {
        let url = "https://www.googleapis.com/drive/v3/files/\(file.identifier)?alt=media"
        let fetcher = service.fetcherService.fetcherWithURLString(url)
        
        fetcher.destinationFileURL = targetURL
        fetcher.authorizer?.primeForRefresh!()
        fetcher.receivedProgressBlock = { (bytesWritten, totalBytesWritten) in
            print("bytesWritten \(bytesWritten), totalBytesWritten \(totalBytesWritten)")
        }
        
        fetcher.beginFetchWithCompletionHandler { (data, error) in
            self.fileDownloadAttempts += 1
            if error == nil {
                print("successfully downloaded \(file.name)")
                self.filesActuallyDownloadedCount += 1
            }
            else {
                print("error fetching file \(error) \(data)")
            }
            
            if self.fileDownloadAttempts == self.filesToDownloadCount {
                self.finishRescan()
            }
        }
    }
    
    internal func fetcher(fetcher: GTMSessionFetcher, receivedData dataSoFar: NSData) {
        print("dataSoFar.length \(dataSoFar.length)")
    }
    
    //===================================================================================
    //MARK: Authorization
    //===================================================================================
    
    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
        let scopeString = scopes.joinWithSeparator(" ")
        return GTMOAuth2ViewControllerTouch(
            scope: scopeString,
            clientID: kClientID,
            clientSecret: nil,
            keychainItemName: kKeychainItemName,
            delegate: self,
            finishedSelector: #selector(POGoogleDriveManager.viewController(_:finishedWithAuth:error:))
        )
    }
    
    internal func viewController(vc: UIViewController, finishedWithAuth authResult: GTMOAuth2Authentication, error : NSError?) {
        if let error = error {
            service.authorizer = nil
            showAlert("Authentication Error", message: error.localizedDescription)
            return
        }
        
        service.authorizer = authResult
        authorizationParentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    internal func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.Default,
            handler: nil
        )
        alert.addAction(ok)
        authorizationParentViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
}