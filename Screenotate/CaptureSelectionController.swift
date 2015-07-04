//
//  CaptureSelectionController.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation
import Cocoa

class CaptureSelectionController: NSObject, NSWindowDelegate {
    var selectionWindowArray = [CaptureSelectionWindow]()
    
    let systemWideElement = AXUIElementCreateSystemWide().takeRetainedValue()

    func preCapture() {
        let screens = NSScreen.screens() as! [NSScreen]

        for screen in screens {
            var selectionWindow: CaptureSelectionWindow = CaptureSelectionWindow.init(scr: screen)!

            selectionWindowArray.append(selectionWindow)
            
            selectionWindow.delegate = self
            selectionWindow.makeKeyAndOrderFront(self)
            selectionWindow.display()
        }

        var mouse: NSPoint = NSEvent.mouseLocation()
        var mouseX = mouse.x
        var mouseY = mouse.y
        for window in selectionWindowArray {
            var windowXMin = window.displayRect.origin.x
            var windowXMax = windowXMin + window.displayRect.size.width
            var windowYMin = window.displayRect.origin.y
            var windowYMax = windowYMin + window.displayRect.size.height

            if (windowXMin < mouseX && mouseX < windowXMax) {
                if (windowYMin < mouseY && mouseY < windowYMax) {
                    window.makeKeyAndOrderFront(self)
                }
            }
        }
    }

    func windowWillClose(notification: NSNotification) {
        let selectionWindow = notification.object as! CaptureSelectionWindow

        if selectionWindow.isSelectionDone! {
            for window in selectionWindowArray {
                if (window != selectionWindow) {
                    window.close()
                }
                
                let contentView = window.contentView as! NSView
                contentView.hidden = true
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.postCapture(selectionWindow)
            })
        }
        
        NSApp.hide(self)
    }

    func postCapture(window: CaptureSelectionWindow) {
        println(window.selectionRect)

        if (!window.isSelectionDone) {
            return
        }
        
        if (!(window.selectionRect.size.width != 0 && window.selectionRect.size.height != 0)) {
            return
        }
        
        usleep(30000)

        let origin = window.selectionRect.origin

        var uelement: Unmanaged<AXUIElement>? = nil
        var err = AXUIElementCopyElementAtPosition(systemWideElement, Float(origin.x), Float(origin.y), &uelement)
        if (Int(err) != Int(kAXErrorSuccess) || uelement == nil) {
            return
        }

        var element = uelement!.takeRetainedValue()

        let title = UIElementUtilities.titleOfUIElement(element)

        let originWindow = windowUIElement(element)
        let windowTitle = UIElementUtilities.titleOfUIElement(originWindow)
        
        let originApplication = applicationUIElement(element)
        let applicationTitle = UIElementUtilities.titleOfUIElement(originApplication)

        let mainID = window.displayID
        let mainCGImage = CGDisplayCreateImage(mainID).takeUnretainedValue() // TODO is this retained
        // note that CGImageCreateWithImageInRect takes pixel rect, not point rect:
        // https://stackoverflow.com/questions/28469202/why-does-cgimagecreatewithimageinrect-take-a-cgrect-with-points-but-then-use-pix
        // so we need to convertRectToBacking
        let mainCroppedCGImage = CGImageCreateWithImageInRect(mainCGImage, window.convertRectToBacking(window.selectionRect))

        var mainMutData = NSMutableData()
        let dspyDestType = "public.png"
        var mainDest = CGImageDestinationCreateWithData(mainMutData, dspyDestType, 1, nil)

        CGImageDestinationAddImage(mainDest, mainCroppedCGImage, nil)
        CGImageDestinationFinalize(mainDest)
        
        let uri = "data:image/png;base64,\(mainMutData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros))"
        let uriSafe = uri
        
        if let dirs: [String] = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as? [String] {
            
            let dir = dirs[0]

            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
            let timestamp = formatter.stringFromDate(date)
            let timestampSafe = timestamp

            let filename = "Screen Shot \(timestamp).html" // it's safe, timestamp was generated by us
            let path = dir.stringByAppendingPathComponent(filename)

            let windowTitleSafe = windowTitle != nil ? htmlEncode(windowTitle) : "[untitled]"

            let heightSafe = window.selectionRect.height
            
            let html = "\n".join([
                "<html>",
                    "<head>",
                        "<title>\(windowTitleSafe), \(timestampSafe)</title>",
                    "</head>",
                    "<body>",
                        "<div>",
                            "<img height=\"\(heightSafe)\" src=\"\(uriSafe)\">",
                        "</div>",
                        "<div>",
                            "<dl>",
                                "<dt>Timestamp</dt>",
                                "<dd>\(timestampSafe)</dd>",
                                "<dt>Window title</dt>",
                                "<dd>\(windowTitleSafe)</dd>",
                                "<dt>App title</dt>",
                                "<dd>\(htmlEncode(applicationTitle))</dd>",
                            "</dl>",
                        "</div>",
                    "</body>",
                "</html>"
                ])
            html.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
            
            NSWorkspace.sharedWorkspace().openFile(path)
        }
    }
}