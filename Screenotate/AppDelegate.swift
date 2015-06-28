//
//  AppDelegate.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Cocoa
import Carbon

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    let keyCode = UInt16(kVK_ANSI_5)
    let keyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let options = NSDictionary(object: kCFBooleanTrue, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionaryRef
        let trusted = AXIsProcessTrustedWithOptions(options)
        if (trusted == 1) {
            NSEvent.addGlobalMonitorForEventsMatchingMask(.KeyDownMask, handler: self.handler)
        }
    }
    
    func handler(event: NSEvent!) {
        if event.keyCode == self.keyCode && (event.modifierFlags & self.keyMask == self.keyMask) {
            println("PRESSED")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
