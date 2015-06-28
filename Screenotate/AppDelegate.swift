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

    let keyCode = UInt(kVK_ANSI_5)
    let keyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask

    var controller: CaptureSelectionController?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let shortcut = MASShortcut(keyCode: keyCode, modifierFlags: keyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(shortcut, withAction: self.handler)
    }
    
    func handler() {
        if (controller? != nil) {
            controller = nil

        } else {
            controller = CaptureSelectionController()
            controller?.preCapture()
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
