//
//  TTUScreenView.swift
//  ttune
//
//  Created by Hiromichi Matsushima on 2017/04/27.
//  Copyright © 2017年 Hiromichi Matsushima. All rights reserved.
//

import Cocoa
import Foundation

class TTUScreenView: NSView {
    var title: String!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        self.title = "foobar"
        if let theView = self.loadFromNib() {
            theView.frame = self.bounds
            self.addSubview(theView)
        }
    }

    private func loadFromNib() -> TTUScreenView? {
        var topLevelObjects:NSArray?
        let bundle = NSBundle.mainBundle()
        if bundle.loadNibNamed("TTUScreenView", owner: nil, topLevelObjects: &topLevelObjects) {
        //let nib = NSNib(nibNamed: "TTUScreenView", bundle: bundle)
        //if nib!.instantiateWithOwner(self, topLevelObjects: &topLevelObjects) {
            for obj in topLevelObjects! {
                if obj.isKindOfClass(NSView) {
                    return obj as? TTUScreenView
                }
            }
        }
        return nil
    }
    
    override func drawRect(dirtyRect: NSRect) {
        if ((self.title) != nil) {
            NSColor(red: 255, green: 255, blue: 255, alpha: 50).setFill()
            NSRectFill(dirtyRect)

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
    }
}