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
    dynamic var title = ""
    dynamic var duration = ""

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
        if bundle.loadNibNamed("TTUScreenView", owner: self, topLevelObjects: &topLevelObjects) {
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
/*
        if ((self.title) != nil) {
            let font = NSFont(name: "Helvetica", size: 12)
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.Center
            let attrs = [
                NSFontAttributeName: font!,
                NSParagraphStyleAttributeName: style
            ]
            let attrString = NSAttributedString(string: self.title, attributes: attrs)

            let rect = dirtyRect
            attrString.drawInRect(rect)
            
        }
*/      
    }
}