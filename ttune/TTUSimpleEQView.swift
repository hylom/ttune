//
//  TTUSimpleEQView.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/05/06.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Foundation
import Cocoa

class TTUSimpleEQView: NSView {
    weak var delegate: TTUSimpleEQViewDelegate! = nil
    dynamic var bassEQ = Float(0.0)
    dynamic var trebleEQ = Float(0.0)
    dynamic var playSpeed = Float(0.0)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        if let theView = self.loadFromNib() {
            theView.frame = self.bounds
            self.addSubview(theView)
        }
    }
    
    private func loadFromNib() -> NSView? {
        var topLevelObjects:NSArray?
        let bundle = NSBundle.mainBundle()
        if bundle.loadNibNamed("TTUSimpleEQView", owner: self, topLevelObjects: &topLevelObjects) {
            for obj in topLevelObjects! {
                if obj.isKindOfClass(NSView) {
                    return obj as? NSView
                }
            }
        }
        return nil
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor(red: 255, green: 255, blue: 255, alpha: 50).setFill()
        // NSRectFill(dirtyRect)
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 10.0, yRadius: 10.0)
        path.fill()
    }
    
    @IBAction func changeBassEQ(sender: AnyObject) {
        if let d = delegate {
            d.changeBassEQ(bassEQ, sender: self)
        }
    }

    @IBAction func changeTrebleEQ(sender: AnyObject) {
        if let d = delegate {
            d.changeTrebleEQ(trebleEQ, sender: self)
        }
    }

    @IBAction func changeSpeed(sender: AnyObject) {
        if let d = delegate {
            d.changePlaySpeed(playSpeed, sender: self)
        }
    }
}

protocol TTUSimpleEQViewDelegate: class {
    func changeBassEQ(value: Float, sender: TTUSimpleEQView)
    func changeTrebleEQ(value: Float, sender: TTUSimpleEQView)
    func changePlaySpeed(value: Float, sender: TTUSimpleEQView)
}