//
//  AppDelegate.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Cocoa
import Carbon

import OAuth2

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var preferencesWindow: NSWindow!
    
    var statusBar: NSStatusItem!

    let keyCode = UInt(kVK_ANSI_5)
    let keyMask: NSEventModifierFlags = .CommandKeyMask | .ShiftKeyMask

    var settings: OAuth2JSON!
    var oauth2: OAuth2ImplicitGrant!

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

        let keys = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Keys", ofType: "plist")!)!
        let appKey = keys["Dropbox API key"] as! String

        settings = [
            "client_id": appKey,
            "authorize_uri": "https://www.dropbox.com/1/oauth2/authorize",
            "token_uri": "https://api.dropbox.com/1/oauth2/token",
            "redirect_uris": ["db-" + appKey + "://oauth/callback"]
        ] as OAuth2JSON

        oauth2 = OAuth2ImplicitGrant(settings: settings)
        oauth2.viewTitle = "Screenotate"
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
        oauth2.authorize()
    }

    func authHelperStateChangedNotification(notification: NSNotification) {
//        println(DBSession.sharedSession().isLinked())
    }

    @IBAction func quitScreenotate(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
