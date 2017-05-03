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

    private var nextContent: TTUContentMO? = nil
    private var currentContent: TTUContentMO? = nil
    private var timer: NSTimer? = nil

    private var engine: AVAudioEngine = AVAudioEngine()
    private var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    private var currentFile: AVAudioFile? = nil
    
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
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        engine.attachNode(playerNode)
        let mixer = engine.mainMixerNode
        engine.connect(playerNode, to: mixer, format: mixer.outputFormatForBus(0))
        do {
            try engine.start()
        } catch {
            print("AVAudioEngine can't start...")
        }
    }
    
    private func startPlay() -> Bool {
        if let next = nextContent {
            if currentContent == nil || currentContent!.path != next.path {
                // play next content
                playerNode.stop()
                currentContent = nextContent
                let url = NSURL(fileURLWithPath: next.path)
                do {
                    try currentFile = AVAudioFile(forReading: url)
                    playerNode.scheduleFile(currentFile!, atTime: nil, completionHandler: nil)
                    playerNode.play()
                } catch {
                    return false
                }
                return true
            } else {
                // resume current content
                playerNode.play()
                return true
            }
        }
        return false
    }
    
    private func stopPlay() {
        playerNode.pause()
        
    }
    
    func updateTime() {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        
        if let t = playerNode.lastRenderTime {
            if let pt = playerNode.playerTimeForNodeTime(t) {
                let ct = Double(pt.sampleTime) / Double(pt.sampleRate)
                self.screenView.duration = formatter.stringFromTimeInterval(NSTimeInterval(ct))!
            }
        } else {
            self.screenView.duration = formatter.stringFromTimeInterval(0.0)!
        }
    }
    
    private func metadatasFromURL(pathString: String) -> [AVMetadataItem] {
        let url = NSURL(fileURLWithPath: pathString)
        let asset = AVAsset(URL: url)
        return asset.commonMetadata
    }

    // UI actions
    @IBAction func togglePlayState(sender: AnyObject) {
        if (isPlaying) {
            // play
            if !startPlay() {
                isPlaying = false
            }
        } else {
            // pause
            stopPlay()
        }
    }

    @IBAction func changeVolume(sender: AnyObject) {
        /*
        if let p = self.player {
            p.volume = volumeSlider.floatValue / 100.0
        }
        */
    }
    
    // tableView delegates
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let contents = contentTableViewController.selectedObjects {
            if contents.count == 1 {
                if let p = contents.first as? TTUContentMO {
                    nextContent = p
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

