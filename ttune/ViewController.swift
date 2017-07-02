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

    fileprivate var nextContent: TTUContentMO? = nil
    fileprivate var currentContent: TTUContentMO? = nil
    fileprivate var timer: Timer? = nil

    fileprivate var engine = AVAudioEngine()
    fileprivate var playerNode = AVAudioPlayerNode()
    fileprivate var eqNode = AVAudioUnitEQ(numberOfBands: 2)
    fileprivate var tsNode = AVAudioUnitTimePitch()
    fileprivate var currentFile: AVAudioFile? = nil
    fileprivate var currentDurationInSample: Int64 = 0
    fileprivate var currentBuffer = AVAudioPCMBuffer()
    fileprivate var isSeeking = false
    fileprivate var playTimeOffset = 0.0
    
    override var representedObject: Any? {
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
        contentTableView.register(forDraggedTypes: [NSFilenamesPboardType])
        
        // add double-click handler
        contentTableView.doubleAction = #selector(ViewController.onTableViewDoubleClick)
        //contentTableView.doubleAction = #selector(onTableViewDoubleClick)
        
        // Update columns
        for item in ["title", "volume", "album", "artist", "time"] {
            if let title = contentTableRowDifinitions[item] {
                let col = NSTableColumn(identifier: item)
                col.title = title
                contentTableView.addTableColumn(col)
                col.bind(NSValueBinding, to: contentTableViewController, withKeyPath: "objectValue." + item, options: nil)
            }
            
        }

        // Initialize timer
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.updateTime), userInfo: nil, repeats: true)
        isPlaying = false
        
        // Initialize notification
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updatePresetVolume), name: NSNotification.Name.NSControlTextDidEndEditing, object: nil)

        // Initialize AVAudioEngine
        // Bass EQ
        let eq1 = eqNode.bands[0]
        eq1.bypass = false
        eq1.filterType = .lowShelf
        eq1.frequency = 6400
        eq1.gain = 0.0
        // Treble EQ
        let eq2 = eqNode.bands[1]
        eq2.bypass = false
        eq2.filterType = .highShelf
        eq2.frequency = 220
        eq2.gain = 0.0

        engine.attach(playerNode)
        engine.attach(eqNode)
        engine.attach(tsNode)

        let mixer = engine.mainMixerNode
        engine.connect(playerNode, to: tsNode, format: mixer.outputFormat(forBus: 0))
        engine.connect(tsNode, to: eqNode, format: mixer.outputFormat(forBus: 0))
        engine.connect(eqNode, to: mixer, format: mixer.outputFormat(forBus: 0))
        setVolume()
        do {
            try engine.start()
        } catch {
            print("AVAudioEngine can't start...")
        }
    }
    
    override func keyUp(with theEvent: NSEvent) {
        //print("keyUp: \(theEvent)")
        if theEvent.characters == " " {
            if (isPlaying) {
                isPlaying = false
                stopPlay()
            } else {
                isPlaying = startPlay()
            }
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
    
    fileprivate func startPlay() -> Bool {
        if let next = nextContent {
            if currentContent == nil || currentContent!.path != next.path {
                // play next content
                playTimeOffset = 0.0
                playerNode.stop()
                currentContent = next
                setVolume()
                let url = URL(fileURLWithPath: next.path)
                do {
                    // disconnect to update playerNode's output format
                    playerNode.reset()
                    engine.disconnectNodeOutput(eqNode)
                    engine.disconnectNodeOutput(tsNode)
                    engine.disconnectNodeOutput(playerNode)

                    try currentFile = AVAudioFile(forReading: url)
                    guard let f = currentFile else { return false }
                    currentDurationInSample = f.length
                    currentBuffer = AVAudioPCMBuffer(pcmFormat: f.processingFormat, frameCapacity: AVAudioFrameCount(f.length))
                    try f.read(into: currentBuffer)

                    playerNode.scheduleBuffer(currentBuffer, completionHandler: playComplete)
                    let mixer = engine.mainMixerNode
                    engine.connect(playerNode, to: tsNode, format: f.processingFormat)
                    engine.connect(tsNode, to: eqNode, format: f.processingFormat)
                    engine.connect(eqNode, to: mixer, format: f.processingFormat)
                    
                    // for debug
                    //print("rate: \(f.processingFormat.sampleRate) - \(tsNode.outputFormatForBus(0).sampleRate) - \(eqNode.outputFormatForBus(0).sampleRate) - \(mixer.outputFormatForBus(0).sampleRate)")
                    //print("rate: \(f.processingFormat.sampleRate) - \(mixer.outputFormatForBus(0).sampleRate)")
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
    
    fileprivate func stopPlay() {
        playerNode.pause()
    }
    
    func playComplete() {
        if (isPlaying && !isSeeking) {
            //isPlaying = false
        }
    }
    
    fileprivate func formatTime(_ time: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        if let r = formatter.string(from: time) {
            return r
        }
        return ""
    }

    func updateTime() {
        guard let t = playerNode.lastRenderTime else {
            self.screenView.duration = formatTime(0.0)
            return
        }

        if let pt = playerNode.playerTime(forNodeTime: t) {
            if pt.sampleTime > AVAudioFramePosition(currentBuffer.frameLength) {
                playerNode.stop()
                return
            }
            let ct = Double(pt.sampleTime) / Double(pt.sampleRate)
            self.screenView.duration = formatTime(TimeInterval(ct + playTimeOffset))
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
    
    fileprivate func metadatasFromURL(_ pathString: String) -> [AVMetadataItem] {
        let url = URL(fileURLWithPath: pathString)
        let asset = AVAsset(url: url)
        return asset.commonMetadata
    }
    
    fileprivate func seekToAtSample(_ sample: AVAudioFramePosition) {
        guard let f = currentFile else { return }
        let sampleRate = playerNode.outputFormat(forBus: 0).sampleRate

        isSeeking = true
        playerNode.stop()

        do {
            f.framePosition = sample
            try f.read(into: currentBuffer, frameCount: AVAudioFrameCount(f.length - sample))
            currentBuffer.frameLength = AVAudioFrameCount(f.length - sample)
        }
        catch {
            isSeeking = false
            return
        }

        playTimeOffset = Double(sample) / sampleRate
        playerNode.scheduleBuffer(currentBuffer, at: nil, options: .interrupts, completionHandler: playComplete)

        if (isPlaying) {
            playerNode.play()
        }
        isSeeking = false
    }

    // UI actions
    @IBAction func togglePlayState(_ sender: AnyObject) {
        if (isPlaying) {
            if !startPlay() {
                isPlaying = false
            }
        } else {
            stopPlay()
        }
    }
    @IBAction func fastRewind(_ sender: AnyObject) {
        if (playTimeOffset != 0.0) {
            seekToAtSample(0)
            return
        }
        isSeeking = true
        playerNode.stop()
        playerNode.scheduleBuffer(currentBuffer, at: nil, options: .interrupts, completionHandler: playComplete)
        screenView.seekSliderPosition = 0
        screenView.duration = formatTime(0.0)
        isSeeking = false

        if (isPlaying) {
            playerNode.play()
        }
    }

    @IBAction func fastForward(_ sender: AnyObject) {
        let sampleRate = playerNode.outputFormat(forBus: 0).sampleRate
        let startTime = AVAudioTime(sampleTime: AVAudioFramePosition(3 * sampleRate), atRate: sampleRate)
        isSeeking = true
        playerNode.stop()
        playerNode.scheduleBuffer(currentBuffer, at: startTime, options: .interrupts, completionHandler: playComplete)
        if (isPlaying) {
            playerNode.play()
        }
        isSeeking = false
    }
    
    @IBAction func changeVolume(_ sender: AnyObject) {
        setVolume()
    }
    
    fileprivate func setVolume() {
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
    func changeSeekSliderPosision(_ value: Double, sender: TTUScreenView) {
        // convert position to sample
        let s = value *  Double(currentDurationInSample) / 100
        seekToAtSample(AVAudioFramePosition(s))
    }
}

extension ViewController: TTUSimpleEQViewDelegate {
    func changeBassEQ(_ value: Float, sender: TTUSimpleEQView) {
        eqNode.bands[0].gain = value
    }

    func changeTrebleEQ(_ value: Float, sender: TTUSimpleEQView) {
        eqNode.bands[1].gain = value
    }

    func changePlaySpeed(_ value: Float, sender: TTUSimpleEQView) {
        tsNode.rate = (100 + value) / 100
    }
}

extension ViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        return .copy
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pboard = info.draggingPasteboard()
        if (pboard.availableType(from: [NSFilenamesPboardType]) == NSFilenamesPboardType) {
            guard let files = pboard.propertyList(forType: NSFilenamesPboardType) as? [String] else { return false }
            guard let moc = contentTableViewController.managedObjectContext else { return false }
            for path in files {
                //print("drop: \(item)")
                let url = URL(fileURLWithPath: path)
                let asset = AVAsset(url: url)
                if !asset.isPlayable {
                    continue
                }
                
                let content = NSEntityDescription.insertNewObject(forEntityName: "Content", into: moc) as! TTUContentMO
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
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let contents = contentTableViewController.selectedObjects, contents.count == 1 {
            if let p = contents.first as? TTUContentMO {
                nextContent = p
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let tableColumn = tableColumn {
            guard let item = contentTableRowDifinitions[tableColumn.identifier] else {
                return nil
            }
            let view = NSTableCellView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
            view.identifier = tableColumn.identifier
            let field = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn.width, height: tableView.rowHeight))
            field.identifier = tableColumn.identifier
            field.bind(NSValueBinding, to: view, withKeyPath: "objectValue." + item, options: nil)
            field.drawsBackground = false
            field.isBordered = false
            view.textField = field
            view.addSubview(field)
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        /*
        for i in 0..<rowView.numberOfColumns {
            let cellView = rowView.viewAtColumn(i)
            if (cellView == nil) {
                print("col \(i): nill")
            }
        }
        */
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
        guard let col = notification.userInfo?["NSTableColumn"] as? NSTableColumn else { return }
        let width = col.width
        print("resized to \(width)")
    }

}

