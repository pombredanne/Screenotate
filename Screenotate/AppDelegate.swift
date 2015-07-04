//
//  AppDelegate.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Cocoa

import MASShortcut

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var preferencesWindow: NSWindow!

    @IBOutlet weak var keyShortcut: MASShortcutView!

    @IBOutlet weak var linkButton: NSButton!
    
    var statusBar: NSStatusItem!

    let keyCode = UInt(kVK_ANSI_5)
    let keyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask

    var controller: CaptureSelectionController?

    var dropboxLoader: DropboxLoader!

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

        dropboxLoader = DropboxLoader()

        NSAppleEventManager.sharedAppleEventManager().setEventHandler(
            self,
            andSelector: "handleURLEvent:withReply:",
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    func handler() {
        NSApp.activateIgnoringOtherApps(true)

        controller = CaptureSelectionController()
        controller?.preCapture()
    }

    @IBAction func showPreferencesWindow(sender: AnyObject) {
        preferencesWindow.makeKeyAndOrderFront(self)
        NSApp.activateIgnoringOtherApps(true)
    }

    @IBAction func linkToDropbox(sender: AnyObject) {
        if !dropboxLoader.linked {
            dropboxLoader.linkToDropbox({ wasFailure, error in
                self.updateLinkButton()
            })
        } else {
            dropboxLoader.unlinkFromDropbox({
                self.updateLinkButton()
            })
        }
    }

    func handleURLEvent(event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        if let urlString = event.paramDescriptorForKeyword(AEKeyword(keyDirectObject))?.stringValue {
            if let url = NSURL(string: urlString) {
                dropboxLoader.handleURL(url)
            }
        } else {
            NSLog("No valid URL to handle")
        }
    }

    func updateLinkButton() {
        if dropboxLoader.linked {
            self.linkButton.title = "Unlink from Dropbox"
        } else {
            self.linkButton.title = "Link to Dropbox..."
        }
    }

    @IBAction func quitScreenotate(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
