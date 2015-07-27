//
//  CaptureSelectionController.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation
import Cocoa
import Quartz

class CaptureSelectionController: NSObject, NSWindowDelegate {
    var selectionWindowArray = [CaptureSelectionWindow]()
    
    let loader = DropboxLoader.sharedInstance

    func preCapture() {
        let screens = NSScreen.screens() as! [NSScreen]

        for screen in screens {
            var selectionWindow: CaptureSelectionWindow = CaptureSelectionWindow.init(screen: screen)!

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

    func windowUnderPoint(point: NSPoint) -> (name: String?, ownerName: String?)? {
        let infoRef = CGWindowListCopyWindowInfo(CGWindowListOption(kCGWindowListOptionOnScreenOnly), CGWindowID(0))
        let info = infoRef.takeRetainedValue() as! Array<NSDictionary>

        var windowUnderPoint: (name: String?, ownerName: String?)?

        for windowInfo in info {
            let windowBounds = windowInfo["kCGWindowBounds"] as! CFDictionary
            var windowRect = CGRect()
            CGRectMakeWithDictionaryRepresentation(windowBounds, &windowRect)

            let windowLayer = windowInfo["kCGWindowLayer"] as! Int
            let windowOwnerName = windowInfo["kCGWindowOwnerName"] as! String?

            if windowLayer != 0 { // throw out windows we don't care about
                continue
            }

            if windowRect.contains(point) {
                // info is ordered front to back so just return first thing we get
                windowUnderPoint = (
                    name: windowInfo["kCGWindowName"] as! String?,
                    ownerName: windowOwnerName
                )
                break
            }
        }

        return windowUnderPoint
    }

    func frontmostPageOfBrowser(applicationTitle: String) -> (url: String, title: String)? {
        // Note: assumption here that screenshotted tab is frontmost
        // in browser's frontmost window.
        // This fits my personal screenshot flow, but it's a definite
        // disadvantage compared to accessibility which can query any window.
        var pageTitle, pageURL: String!

        if applicationTitle.rangeOfString("Firefox") != nil {
            // :|
            pageURL = MozRepl.getFrontmostURL()

        } else if applicationTitle.rangeOfString("Chrome") != nil || applicationTitle.rangeOfString("Chromium") != nil {
            pageURL = executeScript("tell application \"\(applicationTitle)\" to return URL of active tab of front window")

        } else if applicationTitle.rangeOfString("Safari") != nil {
            pageURL = executeScript("tell application \"\(applicationTitle)\" to return URL of front document")

        } else {
            return nil
        }

        return (pageURL, "")
    }

    func executeScript(script: String) -> String? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error) {
                return output.stringValue
            } else if (error != nil) {
                NSLog("error on executeScript \(script):\n\(error)")
            }
        }

        return nil
    }

    func postCapture(window: CaptureSelectionWindow) {
        if (!window.isSelectionDone) {
            return
        }
        
        if (!(window.selectionRect.size.width != 0 && window.selectionRect.size.height != 0)) {
            return
        }
        
        usleep(30000)

        var origin = window.originPoint
        origin.y = window.frame.height - origin.y // CG wants coordinates from top-left

        let displayTopLeft = CGDisplayBounds(window.displayID).origin
        // origin in global coordinates
        let globalOrigin = NSPoint(
            x: displayTopLeft.x + origin.x,
            y: displayTopLeft.y + origin.y
        )

        // figure out which window is under point
        let windowUnderOrigin = windowUnderPoint(globalOrigin)

        let windowTitle = windowUnderOrigin?.name
        let applicationTitle = windowUnderOrigin?.ownerName

        // if it's a browser window, we maybe can also get the URL
        let originPage = applicationTitle != nil ? frontmostPageOfBrowser(applicationTitle!) : nil

        // actually take the screenshot
        let mainID = window.displayID
        let mainCroppedCGImage = CGDisplayCreateImageForRect(mainID, window.selectionRect)

        var mainMutData = NSMutableData()
        let dspyDestType = "public.png"
        var mainDest = CGImageDestinationCreateWithData(mainMutData, dspyDestType, 1, nil)

        CGImageDestinationAddImage(mainDest, mainCroppedCGImage.takeUnretainedValue(), nil)
        CGImageDestinationFinalize(mainDest)

        saveScreenshot(mainMutData, height: window.selectionRect.height,
            windowTitle: windowTitle, applicationTitle: applicationTitle,
            originPage: originPage)
    }

    func saveScreenshot(data: NSData, height: CGFloat,
        windowTitle: String?, applicationTitle: String?,
        originPage: (String, String)?) {
        // 'height' is the point-height -- that is, it's what we should
        // scale a Retina screenshot down to
        let textSafe = htmlEncodeSafe(pngToText(data))

        let uri = "data:image/png;base64,\(data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros))"
        let uriSafe = uri

        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' h.mm.ss a"
        let timestamp = formatter.stringFromDate(date)
        let timestampSafe = timestamp // it's safe, timestamp was generated by us

        let filename = "Screenshot \(timestampSafe).html"
        let windowTitleSafe = windowTitle != nil ? htmlEncodeSafe(windowTitle!) : "[untitled]"
        let applicationTitleSafe = applicationTitle != nil ? htmlEncodeSafe(applicationTitle!) : "[unknown]"

        let heightSafe = height

        let htmlLines = [
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
                            originPage != nil ?
                                "<dt>URL</dt><dd><a href=\"\(htmlEncodeSafe(originPage!.0))\">\(htmlEncodeSafe(originPage!.0))</a></dd>" :
                                "",
                            "<dt>Timestamp</dt>",
                            "<dd>\(timestampSafe)</dd>",
                            "<dt>Window title</dt>",
                            "<dd>\(windowTitleSafe)</dd>",
                            "<dt>App title</dt>",
                            "<dd>\(applicationTitleSafe)</dd>",
                            "<dt>Text</dt>",
                            "<dd><pre>\(textSafe)</pre></dd>",
                        "</dl>",
                    "</div>",
                "</body>",
            "</html>"
            ]
        let html = NSArray(array: htmlLines).componentsJoinedByString("\n")

        // now we have to make the file in either Dropbox or folder
        let defaults = NSUserDefaults.standardUserDefaults()
        let destination = defaults.stringForKey(kScreenshotDestination)

        if destination == kScreenshotDestinationFolder {
            let url = defaults.URLForKey(kSaveFolder)!
            saveToFolder(url, filename: filename, html: html)

        } else if destination == kScreenshotDestinationDropbox {
            loader.upload(filename, data: html.dataUsingEncoding(NSUTF8StringEncoding)!, callback: { dict, error in
                let url = defaults.URLForKey(kOfflineDropboxSaveFolder)!
                if let error = error {
                    self.showError(error.description)

                    // fall back on offline save
                    self.saveToFolder(url, filename: filename, html: html)

                } else if let error = dict!["error"] as? String {
                    self.showError(error)
                    self.saveToFolder(url, filename: filename, html: html)

                } else {
                    // copy Dropbox share URL to clipboard
                    self.copyShareURL(filename, title: windowTitle)
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

    func copyShareURL(filename: String, title: String?) {
        loader.shares(filename, callback: { dict, error in
            if let error = error {
                self.showError(error.description)

            } else if let error = dict!["error"] as? String {
                self.showError(error)

            } else {
                // copy shared link to clipboard
                var url = dict!["url"] as! String
                url += "&raw=1"
                NSPasteboard.generalPasteboard().clearContents()
                NSPasteboard.generalPasteboard().setString(url, forType: NSPasteboardTypeString)

                self.showNotification(title)
            }
        })
    }

    func showError(error: String) {
        println(error)

        var notification = NSUserNotification()
        notification.title = "Screenshot Sharing Error"
        notification.informativeText = "Saved to local folder instead. \(error)"
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }

    func showNotification(title: String?) {
        var notification = NSUserNotification()
        notification.title = "Sharing Screenshot"
        if let title = title {
            notification.informativeText = "A link to your screenshot of '\(title)' has been copied to the Clipboard."
        } else {
            notification.informativeText = "A link to your screenshot has been copied to the Clipboard."
        }
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
}