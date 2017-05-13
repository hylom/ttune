//
//  ViewController.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/09.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Cocoa
import AVFoundation


class ViewController: NSViewController {
    @IBOutlet var contentTableViewController: NSArrayController!
    @IBOutlet weak var contentTableView: NSTableView!
    @IBOutlet weak var screenView: TTUScreenView!
    @IBOutlet weak var volumeSlider: NSSliderCell!
    @IBOutlet weak var simpleEQView: TTUSimpleEQView!

    dynamic var isPlaying = false

    private var nextContent: TTUContentMO? = nil
    private var currentContent: TTUContentMO? = nil
    private var timer: NSTimer? = nil

    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 2)
    private var tsNode = AVAudioUnitTimePitch()
    private var currentFile: AVAudioFile? = nil
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        simpleEQView.delegate = self

        // prepare for Drag and Drop
        contentTableView.registerForDraggedTypes([NSFilenamesPboardType])

        // Initialize timer
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        isPlaying = false

        // Initialize AVAudioEngine
        // Bass EQ
        let eq1 = eqNode.bands[0]
        eq1.bypass = false
        eq1.filterType = .LowShelf
        eq1.frequency = 6400
        eq1.gain = 0.0
        // Treble EQ
        let eq2 = eqNode.bands[1]
        eq2.bypass = false
        eq2.filterType = .HighShelf
        eq2.frequency = 120
        eq2.gain = 0.0

        engine.attachNode(playerNode)
        engine.attachNode(eqNode)
        engine.attachNode(tsNode)

        let mixer = engine.mainMixerNode
        engine.connect(playerNode, to: tsNode, format: mixer.outputFormatForBus(0))
        engine.connect(tsNode, to: eqNode, format: mixer.outputFormatForBus(0))
        engine.connect(eqNode, to: mixer, format: mixer.outputFormatForBus(0))
        mixer.outputVolume = volumeSlider.floatValue / 100.0
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
                currentContent = next
                let url = NSURL(fileURLWithPath: next.path)
                do {
                    try currentFile = AVAudioFile(forReading: url)
                    playerNode.scheduleFile(currentFile!, atTime: nil, completionHandler: nil)
                    playerNode.play()
                    screenView.title = next.title
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
                
                if let currentFile = currentFile {
                    self.screenView.seekSliderPosition = 100 * ct * pt.sampleRate / Double(currentFile.length)
                }
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
    
    private func seekAndPlayAt(time: Double) {
        let sampleRate = playerNode.outputFormatForBus(0).sampleRate
        playerNode.pause()
        let frame = AVAudioFramePosition(time * sampleRate)
        playerNode.playAtTime(AVAudioTime(sampleTime: frame, atRate: sampleRate))
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
    @IBAction func fastRewind(sender: AnyObject) {
        if (isPlaying) {
            playerNode.stop()
            let url = NSURL(fileURLWithPath: currentContent!.path)
            do {
                try currentFile = AVAudioFile(forReading: url)
                playerNode.scheduleFile(currentFile!, atTime: nil, completionHandler: nil)
                playerNode.play()
            } catch {
            }
        }
    }

    @IBAction func fastForward(sender: AnyObject) {
    }
    
    @IBAction func changeVolume(sender: AnyObject) {
        let mixer = engine.mainMixerNode
        mixer.outputVolume = volumeSlider.floatValue / 100.0
    }
    
}

extension ViewController: TTUSimpleEQViewDelegate {
    func changeBassEQ(value: Float, sender: TTUSimpleEQView) {
        eqNode.bands[0].gain = value
    }

    func changeTrebleEQ(value: Float, sender: TTUSimpleEQView) {
        eqNode.bands[1].gain = value
    }

    func changePlaySpeed(value: Float, sender: TTUSimpleEQView) {
        tsNode.rate = (100 + value) / 100
    }
}

extension ViewController: NSTableViewDataSource {
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .Copy
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pboard = info.draggingPasteboard()
        if (pboard.availableTypeFromArray([NSFilenamesPboardType]) == NSFilenamesPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String]
            let moc = contentTableViewController.managedObjectContext!
            for path in files! {
                //print("drop: \(item)")
                let url = NSURL(fileURLWithPath: path)
                let asset = AVAsset(URL: url)
                if !asset.playable {
                    continue
                }
                
                let content = NSEntityDescription.insertNewObjectForEntityForName("Content", inManagedObjectContext: moc) as! TTUContentMO
                content.path = path
                content.setMetadataFrom(asset)

                if content.title == "" {
                    content.title = (path as NSString).lastPathComponent
                }
            }
            return true
        }
        return false
    }
}

extension ViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(notification: NSNotification) {
        if let contents = contentTableViewController.selectedObjects {
            if contents.count == 1 {
                if let p = contents.first as? TTUContentMO {
                    nextContent = p
                }
            }
        }
    }
}

