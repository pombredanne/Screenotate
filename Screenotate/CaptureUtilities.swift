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

func htmlEncode(string: String) -> String {
    return CFXMLCreateStringByEscapingEntities(nil, string, nil)! as String
}
