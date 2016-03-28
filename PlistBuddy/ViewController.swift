//
//  ViewController.swift
//  PlistBuddy
//
//  Created by Eric Chen on 22/03/2016.
//  Copyright © 2016 Eric Chen. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    private var _pListDict = [NSURL : NSMutableDictionary]()
    private var _allInfoDict = [String : [NSURL : Any]]()
    @IBOutlet private var _tableView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func locateButtonClicked(sender: NSResponder) {
        _pListDict.removeAll()
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        let fileManager = NSFileManager.defaultManager()
        switch panel.runModal() {
        case NSModalResponseOK:
            do {
                _allInfoDict.removeAll()
                if let url = panel.URLs.first {
                
                    let files = try fileManager.contentsOfDirectoryAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
                    let pListFiles = files.filter{ $0.pathExtension?.caseInsensitiveCompare("plist") ==  .OrderedSame }
                    for filePath in pListFiles {
                        
                        if let pListData = NSMutableDictionary(contentsOfURL: filePath) {
                                _pListDict[filePath] = pListData
                                appendInfoDict(pListData, fileURL: filePath)
                        }
                        
                    }
   
                }
                let alert = NSAlert()
                alert.messageText = _pListDict.count > 0 ? "\(_pListDict.count) plist file located" : "No plist file can be found, please try a different location."
                alert.addButtonWithTitle("OK")
                switch alert.runModal() {
                    default:_tableView.reloadData()
                }
            } catch {
                
            }          
        default:
            break
        }
    }
    
    func appendInfoDict(newDict: NSDictionary, fileURL: NSURL) {
        for key in newDict.allKeys {
            var value = _allInfoDict[key as! String] ?? [NSURL : AnyObject]()
            value[fileURL] = newDict[key as! NSCopying]
            _allInfoDict[key as! String] = value
        }
    }
    
    //MARK: table view delegates
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return _allInfoDict.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellID = tableColumn == tableView.tableColumns[0] ? "KeyCellID" : "ValueCellID"
        let keyText = _allInfoDict[_allInfoDict.startIndex.advancedBy(row)].0
        let values = _allInfoDict[_allInfoDict.startIndex.advancedBy(row)].1
        if let cell = tableView.makeViewWithIdentifier(cellID, owner: nil) as? NSTableCellView {
            let valuesToDisplay = exclusiveValues(values)
            cell.imageView?.image = nil
            if tableColumn == tableView.tableColumns[0] {
                cell.textField?.stringValue = keyText
            } else {
                cell.textField?.editable = valuesToDisplay.count == 1
                cell.textField?.textColor = valuesToDisplay.count == 1 ? NSColor.blackColor() : NSColor.grayColor()
                cell.textField?.tag = row
                cell.textField?.delegate = self
                cell.textField?.stringValue = valuesToDisplay.count == 1 ? valuesToDisplay.first! : "\(valuesToDisplay.count) values in \(_pListDict.count) plist files"
            }
            return cell
        }
        
        return nil
    }
    
    func tableView(tableView: NSTableView, shouldEditTableColumn tableColumn: NSTableColumn?, row: Int) -> Bool {
        let values = _allInfoDict[_allInfoDict.startIndex.advancedBy(row)].1
        let valuesToDisplay = exclusiveValues(values)
        return valuesToDisplay.count == 1
    }
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let row = control.tag
        let keyToUpdate = _allInfoDict[_allInfoDict.startIndex.advancedBy(row)].0
        updateAllPlist(forKey: keyToUpdate, withValue: fieldEditor.string ?? "")
        return true
    }
    
    func updateAllPlist(forKey key: String, withValue value: String) {
        for (fileURL, pListData) in _pListDict {
            pListData[key] = value
            
            pListData.writeToURL(fileURL, atomically: true)
        }
    }
    
    //MARK: helpers
    func exclusiveValues(values: [NSURL: Any]) -> [String]{
        var results = [String]()
        
        for (_, value) in values {
            if value is String {
                let stringValue = value as! String
                if !results.contains(stringValue) {
                    results.append(stringValue)
                }
                
            } else if value is Int {
                let intValue = value as! Int
                if !results.contains("\(intValue)") {
                    results.append("\(intValue)")
                }
            } else if value is Bool {
                let boolValue = value as! Bool
                let stringValue = boolValue ? "true" : "false"
                if !results.contains(stringValue) {
                    results.append(stringValue)
                }
            } else {
                results.append("\(value)")
            }
        }
        
        return results
    }

}

