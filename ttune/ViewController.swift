//
//  ViewController.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/09.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource  {
    
    @IBOutlet weak var contentTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentTableView.registerForDraggedTypes([NSFilenamesPboardType])
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .Copy
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pboard = info.draggingPasteboard()
        if (pboard.availableTypeFromArray([NSFilenamesPboardType]) == NSFilenamesPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String]
            for item in files! {
                print("drop: \(item)")
            }
            return true
        }
        return false
    }
}

