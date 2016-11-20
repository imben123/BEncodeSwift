//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public extension BEncoder {
    
    /**
     Decodes BEncoded data to swift objects
     
     - parameter byteStream: Any class implementing the ByteStream protocol that will feed the
     decoder sequential bytes from BEncoded data.
     
     - throws: BEncoderException.InvalidBEncode if unable to decode the data
     
     - returns: An Int, String, NSData, Array or Dictionary depending on the type of the
     BEncoded data
     */
    public class func decode(_ byteStream: ByteStream) throws -> Any {
        return try self.decode(byteStream, decodeDictionariesWithStringKeys: false)
    }
    
    public class func decode(_ byteStream: ByteStream, decodeDictionariesWithStringKeys: Bool) throws -> Any {
        let firstByte = byteStream.nextByte()
        byteStream.advanceBy(-1)
        
        if firstByte == ascii_i {
            return try self.decodeInteger(byteStream)
        } else if firstByte == ascii_l {
            return try self.decodeList(byteStream, decodeDictionariesWithStringKeys: decodeDictionariesWithStringKeys)
        } else if firstByte == ascii_d {
            if decodeDictionariesWithStringKeys {
                return try self.decodeStringKeyedDictionary(byteStream)
            } else {
                return try self.decodeDictionary(byteStream)
            }
        } else {
            return try self.decodeByteString(byteStream)
        }
    }
    
    /**
     Convenience method to decode NSData.
     */
    public class func decode(_ data: Data) throws -> Any {
        return try self.decode(NSDataByteStream(data: data as Data))
    }
    
    public class func decode(_ data: Data, decodeDictionariesWithStringKeys stringKeys: Bool) throws -> Any {
        return try self.decode(NSDataByteStream(data: data as Data), decodeDictionariesWithStringKeys: stringKeys)
    }

    public class func decodeInteger(_ data: Data) throws -> Int {
        return try self.decodeInteger(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeInteger(_ byteStream: ByteStream) throws -> Int {
        
        try self.testFirstByte(byteStream, expectedFirstByte: ascii_i)

        return try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_e)
    }
    
    fileprivate class func buildAsciiIntegerFromStream(_ byteStream: ByteStream, terminator: Byte) throws -> Int {
        var currentDigit = byteStream.nextByte()
        var result: Int = 0
        while currentDigit != terminator {
            result = try self.appendNextDigitIfNotNil(result, currentDigit: currentDigit)
            currentDigit = byteStream.nextByte()
        }
        return result
    }
    
    fileprivate class func testFirstByte(_ byteStream: ByteStream, expectedFirstByte: Byte) throws {
        let firstByte = byteStream.nextByte()
        if firstByte != expectedFirstByte {
            throw BEncoderException.invalidBEncode
        }
    }
    
    fileprivate class func appendNextDigitIfNotNil(_ integer: Int, currentDigit: Byte?) throws -> Int {
        if let digit = currentDigit {
            return try self.appendAsciiDigitToInteger(integer, digit: digit)
        } else {
            throw BEncoderException.invalidBEncode
        }
    }
    
    fileprivate class func appendAsciiDigitToInteger(_ integer: Int, digit: UInt8) throws -> Int {
        do {
            return try integer.appendAsciiDigit(digit)
        } catch let e as AsciiError where e == AsciiError.invalid {
            throw BEncoderException.invalidBEncode
        }
    }
    
    public class func decodeByteString(_ data: Data) throws -> Data {
        return try self.decodeByteString(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeByteString(_ byteStream: ByteStream) throws -> Data {
        let numberOfBytes = try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_colon)
        if !byteStream.indexIsValid(byteStream.currentIndex + numberOfBytes) {
            throw BEncoderException.invalidBEncode
        }
        return byteStream.nextBytes(numberOfBytes)!
    }

    public class func decodeString(_ data: Data) throws -> String {
        return try self.decodeString(NSDataByteStream(data: data as Data));
    }

    public class func decodeString(_ byteStream: ByteStream) throws -> String {
        let data = try self.decodeByteString(byteStream)
        guard let result = String(asciiData: data as Data?) else {
            throw BEncoderException.invalidBEncode
        }
        return result
    }
    
    public class func decodeList(_ data: Data) throws -> [Any] {
        return try self.decodeList(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeList(_ byteStream: ByteStream) throws -> [Any] {
        return try self.decodeList(byteStream, decodeDictionariesWithStringKeys: false)
    }
    
    public class func decodeList(_ data: Data, decodeDictionariesWithStringKeys stringKeys: Bool) throws -> [Any] {
        return try self.decodeList(NSDataByteStream(data: data as Data), decodeDictionariesWithStringKeys:stringKeys)
    }
    
    public class func decodeList(_ byteStream: ByteStream,
                                 decodeDictionariesWithStringKeys stringKeys: Bool) throws -> [Any] {
        var result: [Any] = []
        let firstByte = byteStream.nextByte()
        
        if firstByte != ascii_l {
            throw BEncoderException.invalidBEncode
        }
        
        var currentByte = byteStream.nextByte()
        while currentByte != ascii_e {
            byteStream.advanceBy(-1)
            let object = try self.decode(byteStream, decodeDictionariesWithStringKeys: stringKeys)
            result.append(object)
            currentByte = byteStream.nextByte()
        }
        return result
    }
    
    public class func decodeDictionary(_ data: Data) throws -> [Data: Any] {
        return try self.decodeDictionary(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeDictionary(_ byteStream: ByteStream) throws -> [Data: Any] {
        
        var result: [Data:Any] = [:]
        
        var currentByte = byteStream.nextByte()
        currentByte = byteStream.nextByte()
        
        while currentByte != ascii_e {
            
            byteStream.advanceBy(-1)
            
            let key = try self.decodeByteString(byteStream)
            let object = try self.decode(byteStream)
            
            result[key] = object
            
            currentByte = byteStream.nextByte()
            
        }
        return result
    }
    
    public class func decodeStringKeyedDictionary(_ data: Data) throws -> [String: Any] {
        return try self.decodeStringKeyedDictionary(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeStringKeyedDictionary(_ byteStream: ByteStream) throws -> [String: Any] {
        
        var result: [String : Any] = [:]
        
        var currentByte = byteStream.nextByte()
        currentByte = byteStream.nextByte()
        
        while currentByte != ascii_e {
            
            byteStream.advanceBy(-1)
            
            let key = try self.decodeString(byteStream)
            let object = try self.decode(byteStream, decodeDictionariesWithStringKeys: true)
            
            result[key] = object
            
            currentByte = byteStream.nextByte()
            
        }
        return result
    }
    
    public class func decodeDictionaryKeysOnly(_ data: Data) throws -> [String: Data] {
        return try self.decodeDictionaryKeysOnly(NSDataByteStream(data: data as Data))
    }
    
    public class func decodeDictionaryKeysOnly(_ byteStream: ByteStream) throws -> [String: Data] {
        
        var result = [String:Data]()
        
        var currentByte = byteStream.nextByte()
        currentByte = byteStream.nextByte()
        
        while currentByte != ascii_e {
            
            byteStream.advanceBy(-1)
            
            let key = try self.decodeString(byteStream)
            
            let startIndex = byteStream.currentIndex
            let _ = try self.decode(byteStream)
            let numberOfBytesInValue = byteStream.currentIndex - startIndex
            byteStream.advanceBy(-numberOfBytesInValue)
            let value = byteStream.nextBytes(numberOfBytesInValue)
            
            result[key] = value
            
            currentByte = byteStream.nextByte()
            
        }
        return result
    }

}
