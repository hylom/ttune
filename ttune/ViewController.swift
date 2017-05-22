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
    dynamic var usePresetVolume = true

    private var nextContent: TTUContentMO? = nil
    private var currentContent: TTUContentMO? = nil
    private var timer: NSTimer? = nil

    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 2)
    private var tsNode = AVAudioUnitTimePitch()
    private var currentFile: AVAudioFile? = nil
    private var currentDurationInSample: Int64 = 0
    private var currentBuffer = AVAudioPCMBuffer()
    private var isSeeking = false
    private var playTimeOffset = 0.0
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        simpleEQView.delegate = self
        screenView.delegate = self

        // prepare for Drag and Drop
        contentTableView.registerForDraggedTypes([NSFilenamesPboardType])
        
        // add double-click handler
        contentTableView.doubleAction = "onTableViewDoubleClick"
        //contentTableView.doubleAction = #selector(onTableViewDoubleClick)
        
        // Update columns
        for item in ["title", "volume", "album", "artist", "time"] {
            if let title = contentTableRowDifinitions[item] {
                let col = NSTableColumn(identifier: item)
                col.title = title
                contentTableView.addTableColumn(col)
                col.bind(NSValueBinding, toObject: contentTableViewController, withKeyPath: "objectValue." + item, options: nil)
            }
            
        }

        // Initialize timer
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateTime", userInfo: nil, repeats: true)
        isPlaying = false
        
        // Initialize notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePresetVolume", name: NSControlTextDidEndEditingNotification, object: nil)

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
        eq2.frequency = 220
        eq2.gain = 0.0

        engine.attachNode(playerNode)
        engine.attachNode(eqNode)
        engine.attachNode(tsNode)

        let mixer = engine.mainMixerNode
        engine.connect(playerNode, to: tsNode, format: mixer.outputFormatForBus(0))
        engine.connect(tsNode, to: eqNode, format: mixer.outputFormatForBus(0))
        engine.connect(eqNode, to: mixer, format: mixer.outputFormatForBus(0))
        setVolume()
        do {
            try engine.start()
        } catch {
            print("AVAudioEngine can't start...")
        }
    }

    func onTableViewDoubleClick() {
        if (isPlaying) {
            stopPlay()
        }
        isPlaying = startPlay()
        
        //let row = contentTableView.clickedRow
        //let item = contentTableViewController.
    }
    
    private func startPlay() -> Bool {
        if let next = nextContent {
            if currentContent == nil || currentContent!.path != next.path {
                // play next content
                playTimeOffset = 0.0
                playerNode.stop()
                currentContent = next
                setVolume()
                let url = NSURL(fileURLWithPath: next.path)
                do {
                    try currentFile = AVAudioFile(forReading: url)
                    guard let f = currentFile else { return false }
                    currentDurationInSample = f.length
                    currentBuffer = AVAudioPCMBuffer(PCMFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length))
                    try f.readIntoBuffer(currentBuffer)

                    // update playerNode's output format
                    engine.disconnectNodeOutput(playerNode)
                    engine.connect(playerNode, to: tsNode, format: f.processingFormat)

                    playerNode.reset()
                    playerNode.scheduleBuffer(currentBuffer, completionHandler: playComplete)
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
    
    func playComplete() {
        if (isPlaying && !isSeeking) {
            //isPlaying = false
        }
    }
    
    private func formatTime(time: Double) -> String {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Positional
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        if let r = formatter.stringFromTimeInterval(time) {
            return r
        }
        return ""
    }

    func updateTime() {
        guard let t = playerNode.lastRenderTime else {
            self.screenView.duration = formatTime(0.0)
            return
        }

        if let pt = playerNode.playerTimeForNodeTime(t) {
            if pt.sampleTime > AVAudioFramePosition(currentBuffer.frameLength) {
                playerNode.stop()
                return
            }
            let ct = Double(pt.sampleTime) / Double(pt.sampleRate)
            self.screenView.duration = formatTime(NSTimeInterval(ct + playTimeOffset))
            if let currentFile = currentFile {
                self.screenView.seekSliderPosition = 100 * (ct + playTimeOffset) * pt.sampleRate / Double(currentFile.length)
            }
        }
    }

    func updatePresetVolume() {
        guard let current = currentContent else { return }
        guard let next = nextContent else { return }
        if current.path == next.path {
            setVolume()
        }
    }
    
    private func metadatasFromURL(pathString: String) -> [AVMetadataItem] {
        let url = NSURL(fileURLWithPath: pathString)
        let asset = AVAsset(URL: url)
        return asset.commonMetadata
    }
    
    private func seekToAtSample(sample: AVAudioFramePosition) {
        guard let f = currentFile else { return }
        let sampleRate = playerNode.outputFormatForBus(0).sampleRate

        isSeeking = true
        playerNode.stop()

        do {
            f.framePosition = sample
            try f.readIntoBuffer(currentBuffer, frameCount: AVAudioFrameCount(f.length - sample))
            currentBuffer.frameLength = AVAudioFrameCount(f.length - sample)
        }
        catch {
            isSeeking = false
            return
        }

        playTimeOffset = Double(sample) / sampleRate
        playerNode.scheduleBuffer(currentBuffer, atTime: nil, options: .Interrupts, completionHandler: playComplete)

        if (isPlaying) {
            playerNode.play()
        }
        isSeeking = false
    }

    // UI actions
    @IBAction func togglePlayState(sender: AnyObject) {
        if (isPlaying) {
            if !startPlay() {
                isPlaying = false
            }
        } else {
            stopPlay()
        }
    }
    @IBAction func fastRewind(sender: AnyObject) {
        if (playTimeOffset != 0.0) {
            seekToAtSample(0)
            return
        }
        isSeeking = true
        playerNode.stop()
        playerNode.scheduleBuffer(currentBuffer, atTime: nil, options: .Interrupts, completionHandler: playComplete)
        screenView.seekSliderPosition = 0
        screenView.duration = formatTime(0.0)
        isSeeking = false

        if (isPlaying) {
            playerNode.play()
        }
    }

    @IBAction func fastForward(sender: AnyObject) {
        let sampleRate = playerNode.outputFormatForBus(0).sampleRate
        let startTime = AVAudioTime(sampleTime: AVAudioFramePosition(3 * sampleRate), atRate: sampleRate)
        isSeeking = true
        playerNode.stop()
        playerNode.scheduleBuffer(currentBuffer, atTime: startTime, options: .Interrupts, completionHandler: playComplete)
        if (isPlaying) {
            playerNode.play()
        }
        isSeeking = false
    }
    
    @IBAction func changeVolume(sender: AnyObject) {
        setVolume()
    }
    
    private func setVolume() {
        let mixer = engine.mainMixerNode
        if usePresetVolume {
            if let presetVolume = currentContent?.volume {
                mixer.outputVolume = volumeSlider.floatValue * presetVolume / 10000.0
                return
            }
        }
        mixer.outputVolume = volumeSlider.floatValue / 100.0
    }
    
}

extension ViewController: TTUScreenViewDelegate {
    func changeSeekSliderPosision(value: Double, sender: TTUScreenView) {
        // convert position to sample
        let s = value *  Double(currentDurationInSample) / 100
        seekToAtSample(AVAudioFramePosition(s))
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
            guard let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String] else { return false }
            guard let moc = contentTableViewController.managedObjectContext else { return false }
            for path in files {
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
        if let contents = contentTableViewController.selectedObjects where contents.count == 1 {
            if let p = contents.first as? TTUContentMO {
                nextContent = p
            }
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let tableColumn = tableColumn {
            guard let item = contentTableRowDifinitions[tableColumn.identifier] else {
                return nil
            }
            let view = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
            view.identifier = tableColumn.identifier
            let field = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn.width, height: tableView.rowHeight))
            field.identifier = tableColumn.identifier
            field.bind(NSValueBinding, toObject: view, withKeyPath: "objectValue." + item, options: nil)
            field.drawsBackground = false
            field.bordered = false
            view.textField = field
            view.addSubview(field)
            return view
        }
        return nil
    }
    
    func tableView(tableView: NSTableView, didAddRowView rowView: NSTableRowView, forRow row: Int) {
        for i in 0..<rowView.numberOfColumns {
            let cellView = rowView.viewAtColumn(i)
            if (cellView == nil) {
                print("col \(i): nill")
            }
        }
    }
    
    func tableViewColumnDidResize(notification: NSNotification) {
        guard let col = notification.userInfo?["NSTableColumn"] as? NSTableColumn else { return }
        let width = col.width
        print("resized to \(width)")
    }

}

