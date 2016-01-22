//
//  AppDelegate.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/27/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Cocoa

import MASShortcut

let kShowInDock = "ShowInDock"
let kKeyShortcut = "KeyShortcut"
let kScreenshotDestination = "ScreenshotDestination" // folder or Dropbox?
let kSaveFolder = "SaveFolder" // if folder, then what folder exactly?
let kOfflineDropboxSaveFolder = "OfflineDropboxSaveFolder" // if Dropbox, then where do we save if offline?

let kScreenshotDestinationFolder = "Folder"
let kScreenshotDestinationDropbox = "Dropbox"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBar: NSStatusItem?
    @IBOutlet weak var statusMenu: NSMenu!

    @IBOutlet weak var preferencesWindow: NSWindow!

    @IBOutlet weak var launchAtLoginCheckbox: NSButton!
    @IBOutlet weak var showInDockCheckbox: NSButton!

    // Global keyboard shortcut
    @IBOutlet weak var shortcutView: MASShortcutView!

    // Folder save options
    @IBOutlet weak var pathControl: NSPathControl!

    // 'connect to Dropbox'
    @IBOutlet weak var authButton: NSButton!

    // Dropbox-link save options
    @IBOutlet weak var ifOfflineLabel: NSTextField!
    @IBOutlet weak var offlineDropboxPathControl: NSPathControl!
    @IBOutlet weak var appFolderLabel: NSTextField!

    // save to folder or to Dropbox? which one?
    @IBOutlet weak var saveScreenshotsToFolderRadio: NSButton!
    @IBOutlet weak var uploadToDropboxRadio: NSButton!

    lazy var defaults = NSUserDefaults.standardUserDefaults()

    var controller: CaptureSelectionController?

    let dropboxLoader = DropboxLoader.sharedInstance

    func createStatusItem() {
        // NSVariableStatusItemLength isn't a symbol in 10.9 for some reason???
        let statusBar = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
        statusBar.image = NSImage(named: "ic_photo_camera")
        statusBar.image?.template = true

        statusBar.menu = self.statusMenu
        statusBar.highlightMode = true
        self.statusBar = statusBar
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let binder = MASShortcutBinder.sharedBinder()
        shortcutView.associatedUserDefaultsKey = kKeyShortcut

        let defaultShortcut = MASShortcut(
            keyCode: UInt(kVK_ANSI_5),
            modifierFlags: (NSEventModifierFlags.CommandKeyMask.union(NSEventModifierFlags.ShiftKeyMask)).rawValue
        )
        binder.registerDefaultShortcuts([kKeyShortcut: defaultShortcut])
        binder.bindShortcutWithDefaultsKey(kKeyShortcut, toAction: self.takeScreenshot)

        updateAuthUI()

        NSAppleEventManager.sharedAppleEventManager().setEventHandler(
            self,
            andSelector: "handleURLEvent:withReply:",
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        let desktopPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DesktopDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] 
        defaults.registerDefaults([
            kShowInDock: false,
            kScreenshotDestination: kScreenshotDestinationFolder,
            kSaveFolder: desktopPath,
            kOfflineDropboxSaveFolder: "~/Dropbox/Apps/Screenotate"
            ])
        pathControl.URL = defaults.URLForKey(kSaveFolder)!
        offlineDropboxPathControl.URL = defaults.URLForKey(kOfflineDropboxSaveFolder)!

        updateDestinationUI()

        // 'launch at login'
        self.launchAtLoginCheckbox.state = NSBundle.mainBundle().isLoginItemEnabled() ? NSOnState : NSOffState

        updateActivationPolicy() // 'show in dock'
    }

    func takeScreenshot() {
        NSApp.activateIgnoringOtherApps(true)

        controller = CaptureSelectionController()
        controller?.preCapture()
    }

    @IBAction func showPreferencesWindow(sender: AnyObject) {
        preferencesWindow.makeKeyAndOrderFront(self)
        preferencesWindow.canHide = false // so doesn't vanish if Dock icon disabled
        NSApp.activateIgnoringOtherApps(true)
    }

    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // open prefs window on dock click
        showPreferencesWindow(self)
        return true
    }

    @IBAction func authToDropbox(sender: AnyObject) {
        if !dropboxLoader.authed {
            dropboxLoader.authToDropbox({ wasFailure, error in
                self.updateAuthUI()
            })
        } else {
            dropboxLoader.unauthFromDropbox({
                self.selectSaveScreenshotsToFolder(self) // force to save to folder now
                self.updateAuthUI()
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

    func updateAuthUI() {
        if dropboxLoader.authed {
            authButton.title = "Disconnect Dropbox"
            uploadToDropboxRadio.enabled = true
            offlineDropboxPathControl.enabled = true
            ifOfflineLabel.textColor = NSColor.controlTextColor()
            appFolderLabel.textColor = NSColor.controlTextColor()

        } else {
            authButton.title = "Connect to Dropbox..."
            uploadToDropboxRadio.enabled = false
            offlineDropboxPathControl.enabled = false
            ifOfflineLabel.textColor = NSColor.disabledControlTextColor()
            appFolderLabel.textColor = NSColor.disabledControlTextColor()
        }
    }

    @IBAction func selectSaveFolder(sender: AnyObject) {
        var url = pathControl.URL!
        if let urlN = pathControl.clickedPathComponentCell()?.URL! {
            url = urlN
        }

        pathControl.URL = url
        defaults.setURL(url, forKey: kSaveFolder)
    }

    @IBAction func selectOfflineDropboxSaveFolder(sender: AnyObject) {
        // TODO remove this bit of code duplication
        var url = offlineDropboxPathControl.URL!
        if let urlN = offlineDropboxPathControl.clickedPathComponentCell()?.URL! {
            url = urlN
        }

        offlineDropboxPathControl.URL = url
        defaults.setURL(url, forKey: kOfflineDropboxSaveFolder)
    }

    @IBAction func selectSaveScreenshotsToFolder(sender: AnyObject) {
        defaults.setObject(kScreenshotDestinationFolder, forKey: kScreenshotDestination)
        updateDestinationUI()
    }
    @IBAction func selectUploadToDropbox(sender: AnyObject) {
        defaults.setObject(kScreenshotDestinationDropbox, forKey: kScreenshotDestination)
        updateDestinationUI()
    }

    func updateDestinationUI() {
        let destination = defaults.stringForKey(kScreenshotDestination)
        if destination == kScreenshotDestinationFolder {
            saveScreenshotsToFolderRadio.state = NSOnState
            uploadToDropboxRadio.state = NSOffState

        } else if destination == kScreenshotDestinationDropbox {
            saveScreenshotsToFolderRadio.state = NSOffState
            uploadToDropboxRadio.state = NSOnState
        }
    }

    @IBAction func selectLaunchAtLogin(sender: AnyObject) {
        switch launchAtLoginCheckbox.state {
        case NSOnState:
            NSBundle.mainBundle().enableLoginItem()
        case NSOffState:
            NSBundle.mainBundle().disableLoginItem()
        default:
            break
        }
    }

    @IBAction func selectShowInDock(sender: AnyObject) {
        if showInDockCheckbox.state == NSOnState {
            defaults.setBool(true, forKey: kShowInDock)
        } else {
            defaults.setBool(false, forKey: kShowInDock)
        }
        updateActivationPolicy()
    }

    func updateActivationPolicy() {
        if defaults.boolForKey(kShowInDock) {
            showInDockCheckbox.state = NSOnState
            NSApp.setActivationPolicy(.Regular)
            if statusBar != nil {
                NSStatusBar.systemStatusBar().removeStatusItem(self.statusBar!)
            }
        } else {
            showInDockCheckbox.state = NSOffState
            NSApp.setActivationPolicy(.Accessory)
            createStatusItem()
        }
    }

    @IBAction func quitScreenotate(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}
