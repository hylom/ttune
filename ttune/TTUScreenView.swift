//
//  TTUScreenView.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/27.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation

class TTUScreenView: NSView {
    weak var delegate: TTUScreenViewDelegate! = nil
    dynamic var title = ""
    dynamic var duration = ""
    dynamic var seekSliderPosition = 0.0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    fileprivate func initialize() {
        if let theView = self.loadFromNib() {
            theView.frame = self.bounds
            self.addSubview(theView)
        }
    }
    
    fileprivate func loadFromNib() -> NSView? {
        var topLevelObjects = NSArray()
        let bundle = Bundle.main
        if bundle.loadNibNamed("TTUScreenView", owner: self, topLevelObjects: &topLevelObjects) {
            for obj in topLevelObjects {
                if obj is NSView {
                    return obj as? NSView
                }
            }
        }
        return nil
    }
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor(red: 248, green: 253, blue: 224, alpha: 100).setFill()
        // NSRectFill(dirtyRect)
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 10.0, yRadius: 10.0)
        path.fill()
    }
    
    @IBAction func changeSeekSliderPosition(_ sender: AnyObject) {
        if let d = delegate {
            d.changeSeekSliderPosision(seekSliderPosition, sender: self)
        }
    }
}

protocol TTUScreenViewDelegate: class {
    func changeSeekSliderPosision(_ value: Double, sender: TTUScreenView)
}
