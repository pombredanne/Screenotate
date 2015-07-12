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

    let loader = DropboxLoader.sharedInstance

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
        if (!window.isSelectionDone) {
            return
        }
        
        if (!(window.selectionRect.size.width != 0 && window.selectionRect.size.height != 0)) {
            return
        }
        
        usleep(30000)

        let origin = window.originPoint

        var uelement: Unmanaged<AXUIElement>?
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

        var originUrl: String?

        if originApplication != nil {
            var oldEnhancedUserInterfaceValue: NSNumber?

            let kAXEnhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

            // remember whether accessibility was on before

            oldEnhancedUserInterfaceValue = UIElementUtilities.valueOfAttribute(kAXEnhancedUserInterfaceAttribute, ofUIElement: originApplication) as? NSNumber

            // either way, get the app to turn on accessibility so we can scrape it
            AXUIElementSetAttributeValue(originApplication, kAXEnhancedUserInterfaceAttribute, 1)

            // now scrape what data we can
            // hack alert
            if let parent = originWindow {
                if applicationTitle.rangeOfString("Firefox") != nil {
                    if let
                        group = childrenOfUIElement(parent)?[0],
                        navigationToolbar = findChildOfUIElement(group, {
                            testStringAttribute($0, kAXTitleAttribute, "Navigation Toolbar")
                        }),
                        addressBar = findChildOfUIElement(navigationToolbar, {
                            testStringAttribute($0, kAXRoleAttribute, kAXTextFieldRole)
                        })
                    {
                        originUrl = UIElementUtilities.valueOfAttribute(kAXValueAttribute, ofUIElement: addressBar) as? String
                    }

                } else if applicationTitle.rangeOfString("Chrome") != nil {
                    if let
                        toolbar = childrenOfUIElement(parent)?[0],
                        addressBar = findChildOfUIElement(toolbar, {
                            testStringAttribute($0, kAXRoleAttribute, kAXTextFieldRole)
                        })
                    {
                        originUrl = UIElementUtilities.valueOfAttribute(kAXValueAttribute, ofUIElement: addressBar) as? String
                    }

                } else if applicationTitle.rangeOfString("Safari") != nil {
                    if let
                        toolbar = findChildOfUIElement(parent, {
                            testStringAttribute($0, kAXRoleAttribute, kAXToolbarRole)
                        }),
                        group1 = findChildOfUIElement(toolbar, {
                            testStringAttribute($0, kAXRoleAttribute, kAXGroupRole)
                        }, 1),
                        addressBar = findChildOfUIElement(group1, {
                            testStringAttribute($0, kAXRoleAttribute, kAXTextFieldRole)
                        })
                    {
                        originUrl = UIElementUtilities.valueOfAttribute(kAXValueAttribute, ofUIElement: addressBar) as? String
                    }
                }
            }

            // now go back to the accessibility state before we started messin' around
            AXUIElementSetAttributeValue(originApplication, kAXEnhancedUserInterfaceAttribute, oldEnhancedUserInterfaceValue)
        }

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

        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        let timestamp = formatter.stringFromDate(date)
        let timestampSafe = timestamp // it's safe, timestamp was generated by us

        let filename = "Screen Shot \(timestampSafe).html"
        let windowTitleSafe = windowTitle != nil ? htmlEncodeSafe(windowTitle) : "[untitled]"

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
                            originUrl != nil ?
                                "<dt>URL</dt><dd><a href=\"\(htmlEncodeSafe(toHref(originUrl!)))\">\(htmlEncodeSafe(originUrl!))</a></dd>" :
                                "",
                            "<dt>Timestamp</dt>",
                            "<dd>\(timestampSafe)</dd>",
                            "<dt>Window title</dt>",
                            "<dd>\(windowTitleSafe)</dd>",
                            "<dt>App title</dt>",
                            "<dd>\(htmlEncodeSafe(applicationTitle))</dd>",
                        "</dl>",
                    "</div>",
                "</body>",
            "</html>"
            ])

        // now we have to make the file in either Dropbox or folder
        let defaults = NSUserDefaults.standardUserDefaults()
        let destination = defaults.stringForKey(kScreenshotDestination)

        if destination == kScreenshotDestinationFolder {
            let url = defaults.URLForKey(kSaveFolder)!
            saveToFolder(url, filename: filename, html: html)

        } else if destination == kScreenshotDestinationDropbox {
            loader.upload(filename, data: html.dataUsingEncoding(NSUTF8StringEncoding)!, callback: { dict, error in
                if error != nil {
                    // fall back on offline save
                    let url = defaults.URLForKey(kOfflineDropboxSaveFolder)!
                    self.saveToFolder(url, filename: filename, html: html)

                } else {
                    // copy Dropbox share URL to clipboard
                    self.copyShareURL(filename)
                }
            })

            // clear clipboard
            NSPasteboard.generalPasteboard().clearContents()
        }
    }

    func saveToFolder(url: NSURL, filename: String, html: String) {
        let path = url.path!.stringByAppendingPathComponent(filename)
        html.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
    }

    func copyShareURL(filename: String) {
        loader.shares(filename, callback: { dict, error in
            if error != nil {
                // TODO report an error
            } else {
                // copy shared link to clipboard
                NSPasteboard.generalPasteboard().clearContents()
                NSPasteboard.generalPasteboard().setString(dict!["url"] as! String, forType: NSPasteboardTypeString)
            }
        })
    }
}