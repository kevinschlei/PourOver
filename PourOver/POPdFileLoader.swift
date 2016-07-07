//
//  POPdFileLoader.swift
//  PourOver
//
//  Created by kevin on 6/17/15.
//  Copyright (c) 2015 labuser. All rights reserved.
//

import Foundation

//notifications:
let kPOPdFileWillLoad = "kPOPdFileWillLoad"
let kPOPdFileDidLoad = "kPOPdFileDidLoad"
let kPOPdFileWillClose = "kPOPdFileWillClose"
let kPOPdFileDidClose = "kPOPdFileDidClose"

//parsing constants
let kMetadataDescriptionString = "//PODESCRIPTION:"
let kDefaultLengthDescriptionString = "//PODEFAULTLENGTH:"

let kLocalGoogleDriveDirectory = kDocumentsPath.stringByAppendingString("/PourOverApp")

class POPdFileLoader {
    
    static let sharedPdFileLoader = POPdFileLoader()
    
    //===================================================================================
    //MARK: Properties
    //===================================================================================
    
    private var pdBaseFileHandle: UnsafeMutablePointer<Void>?
    
    //===================================================================================
    //MARK: Loading
    //===================================================================================
    
    func closePdFile(completionHandler: (() -> ())?) {
        if let handle = pdBaseFileHandle {
            if handle.hashValue != 0x0 {
                pdBaseFileHandle = nil
                
                POPdBase.sendBangToConstCharReceiver("stop")
                
                NSNotificationCenter.defaultCenter().postNotificationName(kPOPdFileWillClose, object: nil)
                delay(0.02) {
                    POPdBase.closeFile(handle)
                    NSNotificationCenter.defaultCenter().postNotificationName(kPOPdFileDidClose, object: nil)
                    if let handler = completionHandler {
                        handler()
                    }
                }
                return
            }
        }
        if let handler = completionHandler {
            handler()
        }
    }
    
    func loadPdFileAtPath(filePath: String) -> Bool {
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            closePdFile() {
                self.completeLoadPdFileAtPath(filePath)
            }
            return true
        }
        else {
            return false
        }
    }
    
    func completeLoadPdFileAtPath(filePath: String) {
        //post notification of impending load:
        NSNotificationCenter.defaultCenter().postNotificationName(kPOPdFileWillLoad, object: nil)
        
        let directoryPath = (filePath as NSString).stringByDeletingLastPathComponent
        pdBaseFileHandle = POPdBase.openFile((filePath as NSString).lastPathComponent, path: directoryPath)
        
        NSNotificationCenter.defaultCenter().postNotificationName(kPOPdFileDidLoad, object: nil)
        
    }
    
    //===================================================================================
    //MARK: Scanning
    //===================================================================================
    
    /**
    Filters top level Pd files by iterating through documents directory. Only files with comments starting with //PODESCRIPTION: (kMetadataDescriptionString) will be included in the pieces array.
    */
    func availablePatchesInDocuments() -> [[String : AnyObject]]? {
        var availablePatches: [[String : AnyObject]] = []
        do {
            let documentDirectoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsDirectoryFilePath) as [String]
            NSLog("%@", documentDirectoryContents)
            for documentName in documentDirectoryContents {
                if (documentName as NSString).pathExtension == "pd" {
                    //remove the file extension:
                    let filePath = (documentsDirectoryFilePath as NSString).stringByAppendingPathComponent(documentName)
                    do {
                        let fileText = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
                        if let description = commentStartingWithString(kMetadataDescriptionString, inText: fileText) {
                            let documentNameNoExtension = (documentName as NSString).stringByDeletingPathExtension
                            var patchDictionary: [String : AnyObject] = [
                                "title" : documentNameNoExtension,
                                "filePath" : filePath,
                                "description" : description
                            ]
                            if let defaultLength = commentStartingWithString(kDefaultLengthDescriptionString, inText: fileText) {
                                if let doubleValue = Double(defaultLength) {
                                    patchDictionary.updateValue(doubleValue, forKey: "defaultLength")
                                }
                            }
                            availablePatches.append(patchDictionary)
                        }
                    }
                    catch _ {
                        print("String(contentsOfFile:encoding:) failed")
                        return nil
                    }
                }
            }
        }
        catch _ {
            print("contentsOfDirectoryAtPath failed")
            return nil
        }
        return availablePatches
    }
    
    func availablePresets() -> [[String : AnyObject]]? {
        var presetPatches: [[String : AnyObject]] = []
        do {
            let presetNames = [
                "Hello World",
                "Parallel"
            ]
            for name in presetNames {
                if let filePath = NSBundle.mainBundle().pathForResource(name, ofType: "pd") {
                    do {
                        let fileText = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
                        if let description = commentStartingWithString(kMetadataDescriptionString, inText: fileText) {
                            var patchDictionary: [String : AnyObject] = [
                                "title" : name,
                                "filePath" : filePath,
                                "description" : description
                            ]
                            if let defaultLength = commentStartingWithString(kDefaultLengthDescriptionString, inText: fileText) {
                                if let doubleValue = Double(defaultLength) {
                                    patchDictionary.updateValue(doubleValue, forKey: "defaultLength")
                                }
                            }
                            presetPatches.append(patchDictionary)
                        }
                    }
                    catch _ {
                        print("String(contentsOfFile:encoding:) failed")
                        return nil
                    }
                }
            }
        }
        return presetPatches
    }
    
    func availablePatchesInLocalGoogleDriveDirectory() -> [[String : AnyObject]]? {
        var availablePatches: [[String : AnyObject]] = []
        addTopLevelPatchesInDirectory(kLocalGoogleDriveDirectory, toAvailablePatches: &availablePatches)
        return availablePatches.sort( {
            if let title0 = $0["title"] as? String,
                let title1 = $1["title"] as? String {
                return title0.localizedCaseInsensitiveCompare(title1) == NSComparisonResult.OrderedAscending
            }
            return false
        })
    }
    
    private func addTopLevelPatchesInDirectory(directory: String, inout toAvailablePatches availablePatches: [[String : AnyObject]]) {
        let fileManager = NSFileManager.defaultManager()
        do {
            let documentDirectoryContents = try fileManager.contentsOfDirectoryAtPath(directory) as [String]
            NSLog("%@", documentDirectoryContents)
            for documentName in documentDirectoryContents {
                let filePath = (directory as NSString).stringByAppendingPathComponent(documentName)
                if (documentName as NSString).pathExtension == "pd" {
                    do {
                        let fileText = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
                        if let description = commentStartingWithString(kMetadataDescriptionString, inText: fileText) {
                            let documentNameNoExtension = (documentName as NSString).stringByDeletingPathExtension
                            var patchDictionary: [String : AnyObject] = [
                                "title" : documentNameNoExtension,
                                "filePath" : filePath,
                                "description" : description
                            ]
                            if let defaultLength = commentStartingWithString(kDefaultLengthDescriptionString, inText: fileText) {
                                if let doubleValue = Double(defaultLength) {
                                    patchDictionary.updateValue(doubleValue, forKey: "defaultLength")
                                }
                            }
                            availablePatches.append(patchDictionary)
                        }
                    }
                    catch _ {
                        print("String(contentsOfFile:encoding:) failed")
                        return
                    }
                }
                
                var isDirectory: ObjCBool = false
                fileManager.fileExistsAtPath(filePath, isDirectory: &isDirectory)
                if isDirectory {
                    addTopLevelPatchesInDirectory(filePath, toAvailablePatches: &availablePatches)
                }
                
            }
        }
        catch _ {
            print("contentsOfDirectoryAtPath failed")
            return
        }
    }
    
    //===================================================================================
    //MARK: File Parsing
    //===================================================================================
    
    /**
    Returns an array of Strings for each object line in a Pd file. The objects are found by separating the full text by line break, then checking that the second string in a line == "obj" and the fourth string is equal to the supplied "object" argument.
    */
    private func objectsInPdFileContents(fileContents: String, named object: String) -> [String] {
        let allLines = fileContents.componentsSeparatedByString("\n")
        let objectLines = allLines.filter {
            let components = $0.componentsSeparatedByString(" ")
            if components.count > 4 {
                return components[1] == "obj" && components[4] == object
            }
            else {
                return false
            }
        }
        return objectLines
    }
    
    /**
    Returns the object argument of the Pd obj if it is supplied.
    
    Given [osc~ 440]
    "argumentIndex" 0
    "object" "#X obj 100 230 osc~ 440"
    returns "440"
    */
    private func argumentAtIndex(argumentIndex: Int, forObject object: String) -> String? {
        let components = object.componentsSeparatedByString(" ")
        if components.count > argumentIndex + 5 {
            let rawArgument = components[argumentIndex + 5]
            let cleaned = rawArgument.stringByReplacingOccurrencesOfString(";", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: rawArgument.characters.indices)
            return cleaned
        }
        return nil
    }
    
    /**
    Returns the remainder of a comment which starts with the supplied string.
    */
    private func commentStartingWithString(startingString: String, inText text: String) -> String? {
        if let _ = text.rangeOfString(startingString, options: NSStringCompareOptions.LiteralSearch, range: nil, locale: nil) {
            //comment found
            let metaDataSplitComponents = text.componentsSeparatedByString(startingString)
            let commentComponents = metaDataSplitComponents[1].componentsSeparatedByString(";")
            var commentString = commentComponents[0] as String
            commentString.cleanPdComment()
            return commentString
        }
        else {
            return nil
        }
    }
}
