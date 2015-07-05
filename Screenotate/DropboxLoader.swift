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
    static let sharedInstance = DropboxLoader()

    let baseURL = NSURL(string: "https://api.dropbox.com/1")!

    var authed: Bool {
        get {
            return self.oauth2.hasUnexpiredAccessToken()
        }
    }

    lazy var appKey = NSBundle.mainBundle().objectForInfoDictionaryKey("DropboxAppKey") as! String
    lazy var oauth2: OAuth2ImplicitGrant = {
        let settings = [
            "client_id": self.appKey,
            "authorize_uri": "https://www.dropbox.com/1/oauth2/authorize",
            "token_uri": "https://api.dropbox.com/1/oauth2/token",
            "redirect_uris": ["db-" + self.appKey + "://oauth/callback"]
            ] as OAuth2JSON

        let oauth2 = OAuth2ImplicitGrant(settings: settings)
        oauth2.viewTitle = "Screenotate"

        return oauth2
    }()

    func authToDropbox(callback: (wasFailure: Bool, error: NSError?) -> Void) {
        oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            if !wasFailure {
                self.request("account/info", callback: { dict, error in
                    if error != nil {
                        NSLog("dropbox error: %@", error!)
                    }
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

    func request(path: String, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
        let url = baseURL.URLByAppendingPathComponent(path)
        let req = oauth2.request(forURL: url)

        sendRequest(req, callback: callback)
    }

    func upload(path: String, data: NSData, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
        let uploadBaseURL = NSURL(string: "https://api-content.dropbox.com/1/files_put/auto/")!
        let url = uploadBaseURL.URLByAppendingPathComponent(path)

        let req = oauth2.request(forURL: url)
        req.HTTPMethod = "PUT"
        req.HTTPBody = data

        sendRequest(req, callback: callback)
    }

    func shares(path: String, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
        let url = baseURL.URLByAppendingPathComponent("shares/auto/").URLByAppendingPathComponent(path)

        let req = oauth2.request(forURL: url)
        req.HTTPMethod = "POST"
        req.HTTPBody = "short_url=false".dataUsingEncoding(NSUTF8StringEncoding)

        sendRequest(req, callback: callback)
    }

    func sendRequest(req: OAuth2Request, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
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

    func unauthFromDropbox(callback: Void -> Void) {
        oauth2.forgetTokens()
        callback()
    }
}