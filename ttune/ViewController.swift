//
//  ViewController.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/09.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Cocoa
import AVFoundation


class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource  {
    
    @IBOutlet var contentTableViewController: NSArrayController!
    @IBOutlet weak var contentTableView: NSTableView!
    @IBOutlet weak var buttonPlayPause: NSButton!

    var isPlaying: Bool = false
    var playing: TTUContentMO? = nil
    var player = AVAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        contentTableView.registerForDraggedTypes([NSFilenamesPboardType])
        isPlaying = false

    }

    // UI actions
    
    @IBAction func togglePlayPause(sender: AnyObject) {
        if (isPlaying) {
            // pause
            player.stop()
            isPlaying = false
            buttonPlayPause.title = "play"
        } else {
            // play
            if let path = playing!.path {
                let url = NSURL(fileURLWithPath: path)
                do {
                    try player = AVAudioPlayer(contentsOfURL: url)
                    player.prepareToPlay()
                    player.play()
                    isPlaying = true
                    buttonPlayPause.title = "stop"
                }
                catch {
                    isPlaying = false
                    buttonPlayPause.title = "play"
                }
                
            }
        }
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // tableView delegates
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let contents = contentTableViewController.selectedObjects {
            if contents.count == 1 {
                playing = contents.first as? TTUContentMO
            }
        }
        if let p = playing {
            let path = p.path
            print("selected: \(path)")
        }
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .Copy
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pboard = info.draggingPasteboard()
        if (pboard.availableTypeFromArray([NSFilenamesPboardType]) == NSFilenamesPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String]
            
            let moc = contentTableViewController.managedObjectContext!
            for item in files! {
                //print("drop: \(item)")
                let content     = NSEntityDescription.insertNewObjectForEntityForName("Content", inManagedObjectContext: moc) as! TTUContentMO
                content.title = item
                content.path = item
            }
            return true
        }
        return false
    }
}

