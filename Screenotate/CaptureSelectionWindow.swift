//
//  CaptureOverlayWindow.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation
import Cocoa

class CaptureSelectionWindow: NSWindow {
    // TODO figure out which of these are constant
    var displayRect: NSRect
    var displayID: CGDirectDisplayID!

    var originPoint: NSPoint!

    var isSelectionDone: Bool!
    var selectionRect: CGRect!

    var trackingArea: NSTrackingArea!
    var selectionView: CaptureSelectionView!

    override var canBecomeKeyWindow: Bool { return true }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override var acceptsMouseMovedEvents: Bool {
        get {
            return true
        }
        set {
            
        }
    }

    init?(scr: NSScreen) {
        displayRect = scr.frame

        // FIXME kind of hacky initial values
        var dspyIDArray: [CGDirectDisplayID] = [0]
        var dspyIDCount: UInt32 = 0

        if Int(CGGetDisplaysWithRect(displayRect, 1, &dspyIDArray, &dspyIDCount)) == Int(kCGErrorSuccess.value) {

            displayID = dspyIDArray[0]

        } else {
            super.init(coder: NSCoder()) // FIXME ???
            return nil
        }

        super.init(contentRect: displayRect, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, defer: true)

        self.level = Int(CGWindowLevelForKey(Int32(kCGMainMenuWindowLevelKey))) + 1
        self.opaque = false
        self.backgroundColor = NSColor.greenColor().colorWithAlphaComponent(0.9) //.whiteColor().colorWithAlphaComponent(0.1)
        self.releasedWhenClosed = false
        self.oneShot = true

        originPoint = NSMakePoint(-1, -1)

        isSelectionDone = false
        selectionRect = NSRectToCGRect(NSMakeRect(-1, -1, -1, -1))

        selectionView = CaptureSelectionView()

        trackingArea = NSTrackingArea(rect: NSMakeRect(0, 0, displayRect.size.width, displayRect.size.height), options: NSTrackingAreaOptions.ActiveAlways | NSTrackingAreaOptions.MouseMoved | NSTrackingAreaOptions.MouseEnteredAndExited, owner: self, userInfo: nil)
    }

    // FIXME ???
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func display() {
        NSCursor.crosshairCursor().set()
        let contentView = self.contentView as NSView
        contentView.addTrackingArea(trackingArea)
        super.display()
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        self.makeKeyAndOrderFront(self)
        NSCursor.crosshairCursor().set()
    }
    
    override func mouseMoved(theEvent: NSEvent) {
        self.makeKeyAndOrderFront(self)
        NSCursor.crosshairCursor().set()
    }
    
    override func mouseDown(theEvent: NSEvent) {

    }
}