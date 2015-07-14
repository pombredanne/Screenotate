//
//  MozReplDelegate.swift
//  Screenotate
//
//  Created by Omar Rizwan on 7/12/15.
//  Copyright (c) 2015 Omar Rizwan. All rights reserved.
//

import Foundation

class MozRepl {
    var inputStream: NSInputStream!
    var outputStream: NSOutputStream!

    func connect() {
        var inp: NSInputStream?
        var out: NSOutputStream?

        let host = NSHost(address: "127.0.0.1")
        NSStream.getStreamsToHost(host, port: 4242, inputStream: &inp, outputStream: &out)

        inputStream = inp!
        outputStream = out!

        inputStream.open()
        outputStream.open()
    }

    func waitForBytesAvailable() {
        while !inputStream.hasBytesAvailable { usleep(10) }
    }

    func waitForPrompt() {
        // wait until we get the prompt "\nrepl[0-9]*> "
        var bytes: [UInt8] = []
        var readByte: UInt8 = 0
        while !(!inputStream.hasBytesAvailable && bytes.count > 5 &&
            bytes[bytes.endIndex - 2] == 62 && bytes.last == 32) {

            inputStream.read(&readByte, maxLength: 1)
            bytes.append(readByte)
        }
    }

    func send(s: String) {
        let data = (s + "\r\n").dataUsingEncoding(NSUTF8StringEncoding)!
        outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
    }

    func readURL() -> String {
        var bytes: [UInt8] = []
        var readByte: UInt8 = 0
        while bytes.last != 10 {
            inputStream.read(&readByte, maxLength: 1)
            bytes.append(readByte)
        }

        return NSString(bytes: bytes, length: bytes.count, encoding: NSUTF8StringEncoding)! as String
    }

    func requestURL() -> String {
        send("content.location.href")
        let ret = readURL()
        return ret.substringWithRange(Range(
            start: advance(ret.startIndex, 1),
            end: advance(ret.endIndex, -2)
            ))
    }

    class func getFrontmostURL() -> String {
        let m = MozRepl()
        m.connect()
        m.waitForPrompt()
        return m.requestURL()
    }
}