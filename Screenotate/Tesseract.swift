//
//  Tesseract.swift
//  Screenotate
//
//  Created by Omar Rizwan on 7/17/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation

let resourcePath = NSBundle.mainBundle().resourcePath!
let tesseractPath = resourcePath.stringByAppendingPathComponent("tesseract")

func pngToText(png: NSData) -> String {
    // So we're going to use a hack here.
    // We're going to write png to a temporary file:
    let fileName = NSString(format: "%@_%@", NSProcessInfo.processInfo().globallyUniqueString, "tmp.png")
    let fileURL = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingPathComponent(fileName as String))!
    png.writeToURL(fileURL, atomically: true)

    // And then we're going to tell tesseract to read that file:
    let task = NSTask()
    task.launchPath = tesseractPath
    task.arguments = [
        "--tessdata-dir", resourcePath,
        fileURL.path!, "stdout"
    ]

    let outPipe = NSPipe()

    task.standardOutput = outPipe
    let outHandle = outPipe.fileHandleForReading

    task.launch()

    return NSString(data: outHandle.readDataToEndOfFile(), encoding: NSUTF8StringEncoding) as! String
}
