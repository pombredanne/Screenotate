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
    var viewRect: NSRect!

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
            fatalError("not able to find displays")
        }

        super.init(contentRect: displayRect, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, defer: true)

        self.level = Int(CGWindowLevelForKey(Int32(kCGMainMenuWindowLevelKey))) + 1
        self.opaque = false
        self.backgroundColor = NSColor.whiteColor().colorWithAlphaComponent(0.1)
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
        originPoint = theEvent.locationInWindow
        viewRect = NSMakeRect(originPoint.x, originPoint.y, 0, 0)
        selectionView.frame = viewRect
        
        let contentView = self.contentView as NSView
        contentView.addSubview(selectionView)
        
        NSCursor.crosshairCursor().set()
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let currentPoint = theEvent.locationInWindow
        
        let viewX = currentPoint.x > originPoint.x ? originPoint.x : currentPoint.x
        let viewY = currentPoint.y > originPoint.y ? originPoint.y : currentPoint.y
        let viewW = currentPoint.x > originPoint.x ? currentPoint.x - originPoint.x : originPoint.x - currentPoint.x
        let viewH = currentPoint.y > originPoint.y ? currentPoint.y - originPoint.y : originPoint.y - currentPoint.y

        viewRect = NSMakeRect(viewX, viewY, viewW, viewH)
        selectionView.frame = viewRect
        NSCursor.crosshairCursor().set()
    }
    
    override func mouseUp(theEvent: NSEvent) {
        isSelectionDone = true
        
        selectionRect = CGRectMake(viewRect.origin.x,
            displayRect.size.height - viewRect.origin.y - viewRect.size.height,
            viewRect.size.width,
            viewRect.size.height)
        
        self.close()
    }
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.keyCode == 53 {
            self.close()
        }
    }
}