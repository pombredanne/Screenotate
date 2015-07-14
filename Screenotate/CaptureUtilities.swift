//
//  CaptureUtilities.swift
//  Screenotate
//
//  Created by Omar Rizwan on 6/28/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation

func htmlEncodeSafe(string: String) -> String {
    return CFXMLCreateStringByEscapingEntities(nil, string, nil)! as String
}
