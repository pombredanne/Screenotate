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

    @IBOutlet weak var shortcutView: MASShortcutView!

    @IBOutlet weak var linkButton: NSButton!
    @IBOutlet weak var uploadToDropboxRadio: NSButton!
    
    var statusBar: NSStatusItem!

    let kKeyShortcut = "KeyShortcut"
    let kScreenshotDestination = "ScreenshotDestination"

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
        let binder = MASShortcutBinder.sharedBinder()
        shortcutView.associatedUserDefaultsKey = kKeyShortcut

        let defaultShortcut = MASShortcut(
            keyCode: UInt(kVK_ANSI_5),
            modifierFlags: (NSEventModifierFlags.CommandKeyMask | NSEventModifierFlags.ShiftKeyMask).rawValue
        )
        binder.registerDefaultShortcuts([kKeyShortcut: defaultShortcut])
        binder.bindShortcutWithDefaultsKey(kKeyShortcut, toAction: self.handler)

        dropboxLoader = DropboxLoader()
        updateLinkUI()

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
                self.updateLinkUI()
            })
        } else {
            dropboxLoader.unlinkFromDropbox({
                self.updateLinkUI()
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

    func updateLinkUI() {
        if dropboxLoader.linked {
            linkButton.title = "Unlink from Dropbox"
            uploadToDropboxRadio.enabled = true

        } else {
            linkButton.title = "Link to Dropbox..."
            uploadToDropboxRadio.enabled = false
        }
    }

    @IBAction func quitScreenotate(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
