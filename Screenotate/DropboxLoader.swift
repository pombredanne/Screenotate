//
//  DropboxLoader.swift
//  Screenotate
//
//  Created by Omar Rizwan on 7/4/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation

import OAuth2

class DropboxLoader {
    let baseURL = NSURL(string: "https://api.dropbox.com/1")!

    var appKey: String!

    var settings: OAuth2JSON!
    var oauth2: OAuth2ImplicitGrant!

    var linked = false

    init() {
        appKey = NSBundle.mainBundle().objectForInfoDictionaryKey("DropboxAppKey") as! String

        settings = [
            "client_id": appKey,
            "authorize_uri": "https://www.dropbox.com/1/oauth2/authorize",
            "token_uri": "https://api.dropbox.com/1/oauth2/token",
            "redirect_uris": ["db-" + appKey + "://oauth/callback"]
            ] as OAuth2JSON

        oauth2 = OAuth2ImplicitGrant(settings: settings)
        oauth2.viewTitle = "Screenotate"

        self.linked = oauth2.hasUnexpiredAccessToken()
    }

    func linkToDropbox(callback: (wasFailure: Bool, error: NSError?) -> Void) {
        oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            self.linked = !wasFailure
            if !wasFailure {
                self.request("account/info", callback: { dict, error in
                    println(dict, error)
                    return
                })
            }
            callback(wasFailure: wasFailure, error: error)
        }
        oauth2.authorize()
    }

    func handleURL(url: NSURL) {
        if "db-" + appKey == url.scheme && "oauth" == url.host {
            oauth2.handleRedirectURL(url)
        }
    }

    /** Perform a request against the GitHub API and return decoded JSON or an NSError. */
    func request(path: String, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
        let url = baseURL.URLByAppendingPathComponent(path)
        let req = oauth2.request(forURL: url)

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(req) { data, response, error in
            if nil != error {
                dispatch_async(dispatch_get_main_queue()) {
                    callback(dict: nil, error: error)
                }
            }
            else {
                var err: NSError?
                let dict = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as? NSDictionary
                dispatch_async(dispatch_get_main_queue()) {
                    callback(dict: dict, error: err)
                }
            }
        }
        task.resume()
    }
    
    func unlinkFromDropbox(callback: Void -> Void) {
        oauth2.forgetTokens()
        self.linked = false
        callback()
    }
}