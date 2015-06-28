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
        let screens = NSScreen.screens() as [NSScreen]

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
        println("window will close")

        let selectionWindow = notification.object as CaptureSelectionWindow

        if selectionWindow.isSelectionDone! {
            for window in selectionWindowArray {
                if (window != selectionWindow) {
                    window.close()
                }
                
                let contentView = window.contentView as NSView
                contentView.hidden = true
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.postCapture(selectionWindow)
            })
        }
    }

    func postCapture(window: CaptureSelectionWindow) {
        println("post capture")
        println(window.selectionRect)

        if (!window.isSelectionDone) {
            return
        }
        
        if (!(window.selectionRect.size.width != 0 && window.selectionRect.size.height != 0)) {
            return
        }
        
        usleep(30000)

        // figure out which window is under point
        let infoRef = CGWindowListCopyWindowInfo(CGWindowListOption(kCGWindowListOptionOnScreenOnly), CGWindowID(0))
        let info = infoRef.takeRetainedValue() as Array<NSDictionary>

        var windowUnderPoint: (name: String?, ownerName: String?)?

        for windowInfo in info {
            let windowBounds = windowInfo["kCGWindowBounds"] as CFDictionary
            var windowRect = CGRect()
            CGRectMakeWithDictionaryRepresentation(windowBounds, &windowRect)

            let windowLayer = windowInfo["kCGWindowLayer"] as Int
            let windowOwnerName = windowInfo["kCGWindowOwnerName"] as String?
            
            if windowOwnerName == "Dock" { // FIXME kind of a hack
                continue
            }
            
            if windowRect.contains(window.selectionRect.origin) {
                // info is ordered front to back so just return
                windowUnderPoint = (
                    name: windowInfo["kCGWindowName"] as String?,
                    ownerName: windowOwnerName
                )
                break
            }
        }

        println(windowUnderPoint)

        let origin = window.selectionRect.origin

        var uelement: Unmanaged<AXUIElement>? = nil
        var err = AXUIElementCopyElementAtPosition(systemWideElement, Float(origin.x), Float(origin.y), &uelement)
        if (Int(err) != Int(kAXErrorSuccess) || uelement == nil) {
            return
        }

        var element = uelement!.takeRetainedValue()
        
        println("title of UI element:")
        println(UIElementUtilities.titleOfUIElement(element))
        
        println("lineage of UI element:")
        println(UIElementUtilities.lineageDescriptionOfUIElement(element))

        var parent = UIElementUtilities.parentOfUIElement(element).takeUnretainedValue()

        var parentTitle = UIElementUtilities.titleOfUIElement(parent)
        println("title of parent:")
        println(parentTitle)

//
//        var data = window.dataWithPDFInsideRect(window.selectionRect)
//        data.writeToFile("/Users/Omar/foo.pdf", atomically: true)

//        var mainID = window.displayID
//        var mainCGImage = CGDisplayCreateImage(mainID).takeUnretainedValue() // TODO is this retained
//        var mainCroppedCGImage = CGImageCreateWithImageInRect(mainCGImage, window.selectionRect)
//
//        var mainMutData = CFDataCreateMutable(nil, 0)
//        var dspyDestType = "public.png"
//        var mainDest = CGImageDestinationCreateWithData(mainMutData, dspyDestType, 1, nil)
//
//        CGImageDestinationAddImage(mainDest, mainCroppedCGImage, nil)
//
//        CGImageDestinationFinalize(mainDest)
    }
}