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
    @IBOutlet weak var screenView: TTUScreenView!
    @IBOutlet weak var volumeSlider: NSSliderCell!

    dynamic var isPlaying: Bool = false
    var playing: TTUContentMO? = nil
    var timer: NSTimer? = nil
    var player: AVAudioPlayer?
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        contentTableView.registerForDraggedTypes([NSFilenamesPboardType])
        isPlaying = false
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTime", userInfo: nil, repeats: true)
    }
    
    func updateTime() {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        if let p = self.player {
            self.screenView.duration = formatter.stringFromTimeInterval(p.currentTime)!
        } else {
            self.screenView.duration = formatter.stringFromTimeInterval(0.0)!
        }
    }
    
    private func initPlayer() {
        if let p = self.player {
            p.volume = volumeSlider.floatValue / 100.0
        }
    }
    
    private func metadatasFromURL(pathString: String) -> [AVMetadataItem] {
        let url = NSURL(fileURLWithPath: pathString)
        let asset = AVAsset(URL: url)
        return asset.commonMetadata
    }

    // UI actions
    @IBAction func togglePlayState(sender: AnyObject) {
        if let p = self.player {
            if (isPlaying) {
                // play
                p.play()
            } else {
                // pause
                p.stop()
            }
        } else {
            isPlaying = false;
        }
        
    }

    @IBAction func changeVolume(sender: AnyObject) {
        if let p = self.player {
            p.volume = volumeSlider.floatValue / 100.0
        }
    }
    
    // tableView delegates
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let contents = contentTableViewController.selectedObjects {
            if contents.count == 1 {
                if let p = contents.first as? TTUContentMO {
                    playing = p
                    screenView.title = p.title
                    let url = NSURL(fileURLWithPath: p.path)
                    do {
                        try player = AVAudioPlayer(contentsOfURL: url)
                        player!.prepareToPlay()
                        initPlayer()
                    }
                    catch {
                        isPlaying = false
                    }
                    
                }
            }
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
                content.path = item
                content.title = (item as NSString).lastPathComponent

                let metadatas = metadatasFromURL(item)
                for metadata in metadatas {
                    if metadata.commonKey == "title" {
                        content.title = (metadata.value as? String)!
                    }
                }
            }
            return true
        }
        return false
    }
    
}

