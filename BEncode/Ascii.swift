//
//  Ascii.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public enum AsciiError: Error {
    case invalid
}

public extension UInt8 {
    
    func asciiValue() throws -> UInt8 {
        if self >= 10 {
            throw AsciiError.invalid
        }
        return self + 48 // 48 is ascii for 0
    }
    
    func fromAsciiValue() throws -> UInt8 {
        if self > 57 || self < 48 {
            throw AsciiError.invalid
        }
        return self - 48 // 48 is ascii for 0
    }
    
}

public extension Int {
    
    func digitsInAscii() -> Data {
        let (head, tailByte) = self.splitAndAsciiEncodeLastDigit()
        if head > 0 {
            return head.digitsInAscii().dataByAppendingData(tailByte)
        }
        return tailByte
    }
    
    fileprivate func splitAndAsciiEncodeLastDigit() -> (head: Int, tail: Data) {
        let (head, tail) = splitDigitsOnLast()
        return (head, try! tail.digitAsAsciiByte())
    }
    
    fileprivate func digitAsAsciiByte() throws -> Data {
        return try UInt8(self).asciiValue().toData() as Data
    }
    
    fileprivate func splitDigitsOnLast() -> (head: Int, tail: Int) {
        return (self / 10, self % 10)
    }
    
    static func fromAsciiData(_ data: Data) throws -> Int {
        if data.count == 0 {
            return 0
        }
        let (headOfData, decodedLastByte) = try self.splitDataAndDecodeLastByte(data)
        let resultOfDecodingTheHead = try self.fromAsciiData(headOfData)
        return decodedLastByte + ( 10 * resultOfDecodingTheHead )
    }
    
    fileprivate static func splitDataAndDecodeLastByte(_ data: Data) throws -> (Data, Int) {
        let (headOfData, lastByte) = self.splitDataBeforeLastByte(data)
        let decodedLastByte = try lastByte.fromAsciiValue()
        return (headOfData, Int(decodedLastByte))
    }
    
    fileprivate static func splitDataBeforeLastByte(_ data: Data) -> (Data, UInt8) {
        let lastByte = data.last!
        let range = Range(uncheckedBounds: (lower: data.startIndex,
                                            upper: data.endIndex.advanced(by: -1)))
        let headOfData = data.subdata(in: range)
        return (headOfData, lastByte)
    }
}

public extension Int {
    
    func appendAsciiDigit(_ asciiDigit: Byte) throws -> Int {
        let digit = Int(try asciiDigit.fromAsciiValue())
        return self*10 + digit
    }
    
}

public extension Character {
    
    func asciiValue() throws -> Data {
        let unicodeScalarCodePoint = self.unicodeScalarCodePoint()
        if !unicodeScalarCodePoint.isASCII {
            throw AsciiError.invalid
        }
        return UInt8(ascii: unicodeScalarCodePoint).toData() as Data
    }
    
    func unicodeScalarCodePoint() -> UnicodeScalar {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        return scalars[scalars.startIndex]
    }
    
}

public extension String {
    
    init?(asciiData: Data?) {
        if asciiData == nil { return nil }
        self.init(data: asciiData!, encoding: String.Encoding.ascii)
    }
    
    func asciiValue() throws -> Data {
        guard let result = (self as NSString).data(using: String.Encoding.ascii.rawValue) else {
            throw AsciiError.invalid
        }
        return result
    }
    
}
