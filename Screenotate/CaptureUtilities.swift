//
//  CaptureUtilities.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/28/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation

func isApplicationUIElement(element: AXUIElement) -> Bool {
    return UIElementUtilities.roleOfUIElement(element) == NSAccessibilityApplicationRole
}

func applicationUIElement(element: AXUIElement) -> AXUIElement? {
    if isApplicationUIElement(element) {
        return element
    }
    
    var parentElement: AXUIElement = element
    while let parentElementN = UIElementUtilities.valueOfAttribute("AXParent", ofUIElement: parentElement) as! AXUIElement? {
        
        parentElement = parentElementN
    }
    
    if isApplicationUIElement(parentElement) {
        return parentElement
    }

    return nil
}

func isWindowUIElement(element: AXUIElement) -> Bool {
    return UIElementUtilities.roleOfUIElement(element) == NSAccessibilityWindowRole
}

func windowUIElement(element: AXUIElement) -> AXUIElement? {
    if isWindowUIElement(element) {
        return element
    }
    
    // TODO do we need the loop?
    var windowElement: AXUIElement = element
    while let windowElementN = UIElementUtilities.valueOfAttribute("AXWindow", ofUIElement: windowElement) as! AXUIElement? {

        windowElement = windowElementN
    }

    if isWindowUIElement(windowElement) {
        return windowElement
    }
    
    return nil
}

func childrenOfUIElement(element: AXUIElement) -> [AXUIElement] {
    return UIElementUtilities.valueOfAttribute(kAXChildrenAttribute, ofUIElement: element) as! [AXUIElement]
}

func findChildOfUIElement(element: AXUIElement, test: AXUIElement -> Bool, index: Int) -> AXUIElement? {
    var numSeen = 0
    for child in childrenOfUIElement(element) {
        if test(child) {
            if numSeen++ >= index {
                return child
            }
        }
    }
    return nil
}

func findChildOfUIElement(element: AXUIElement, test: AXUIElement -> Bool) -> AXUIElement? {
    return findChildOfUIElement(element, test, 0)
}


func testStringAttribute(element: AXUIElement, attribute: String, expectedValue: String) -> Bool {
    return UIElementUtilities.valueOfAttribute(attribute, ofUIElement: element) as! String == expectedValue
}

// kind of a meh regex but should work well enough, and the [uncommon] failure case isn't that bad
// (url becomes relative and breaks for clicking)
let hasProtocolRegex = NSRegularExpression(pattern: "://", options: .allZeros, error: nil)!
func toHref(url: String) -> String {
    // some URLs scraped from address bar are like "example.com/foo" since browsers like to be hip
    // if so, just automatically prefix w/ http://
    if (hasProtocolRegex.numberOfMatchesInString(url, options: .allZeros, range: NSMakeRange(0, count(url))) > 0) {
        return url
    }

    return "http://" + url
}

func htmlEncodeSafe(string: String) -> String {
    return CFXMLCreateStringByEscapingEntities(nil, string, nil)! as String
}
