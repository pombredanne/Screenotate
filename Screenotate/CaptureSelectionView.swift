//
//  CaptureSelectionView.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation
import Cocoa

class CaptureSelectionView: NSView {
    override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().colorWithAlphaComponent(0.1).setFill()
        NSRectFill(dirtyRect)
    }
}