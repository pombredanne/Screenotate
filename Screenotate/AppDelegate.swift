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

    @IBOutlet weak var statusMenu: NSMenu!
    
    var statusBar: NSStatusItem!
    
    var preferencesController: ScreenotatePreferencesController?

    let keyCode = UInt(kVK_ANSI_5)
    let keyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask

    var controller: CaptureSelectionController?

    override func awakeFromNib() {
        // NSVariableStatusItemLength isn't a symbol in 10.9 for some reason???
        self.statusBar = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        self.statusBar.title = "S"

        self.statusBar.menu = self.statusMenu
        self.statusBar.highlightMode = true
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let shortcut = MASShortcut(keyCode: keyCode, modifierFlags: keyMask.rawValue)
        MASShortcutMonitor.sharedMonitor().registerShortcut(shortcut, withAction: self.handler)
    }
    
    func handler() {
        NSApp.activateIgnoringOtherApps(true)

        controller = CaptureSelectionController()
        controller?.preCapture()
    }

    @IBAction func showPreferencesWindow(sender: AnyObject) {
        if preferencesController == nil {
            preferencesController = ScreenotatePreferencesController()
        }
        
        preferencesController?.showWindow(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
