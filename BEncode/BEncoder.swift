//
//  BEncoder.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

enum BEncoderException: Error {
    case invalidAscii
    case invalidBEncode
    case unrepresentableObject
}

open class BEncoder {
    
    static let ascii_i:      Byte = 105
    static let ascii_l:      Byte = 108
    static let ascii_d:      Byte = 100
    static let ascii_e:      Byte = 101
    static let ascii_colon:  Byte = 58
    
    static let IntergerStartToken:       Data = try! Character("i").asciiValue() as Data
    static let ListStartToken:           Data = try! Character("l").asciiValue() as Data
    static let DictinaryStartToken:      Data = try! Character("d").asciiValue() as Data
    static let StructureEndToken:        Data = try! Character("e").asciiValue() as Data
    static let StringSizeDelimiterToken: Data = try! Character(":").asciiValue() as Data
    
    /**
     Creates a NSData object containing the BEncoded representation of the object passed.
     
     - parameter object: Object to be encoded
     
     - throws: BEncoderException if the object cannot be represented in BEncode
     */
    open class func encode(_ object: Any) throws -> Data {
        if object is Int {
            return self.encodeInteger(object as! Int)
        } else if object is String {
            return try self.encodeString(object as! String)
        } else if object is Data {
            return self.encodeByteString(object as! Data)
        } else if object is [Any] {
            return try self.encodeList(object as! [Any])
        } else if object is [String:Any] {
            return try self.encodeDictionary(object as! [String:Any])
        } else if object is [Data:Any] {
            return try self.encodeByteStringKeyedDictionary(object as! [Data:Any])
        }
        throw BEncoderException.unrepresentableObject
    }

    /**
     Creates BEncoded integer
     */
    open class func encodeInteger(_ integer: Int) -> Data {
        let data = (NSData(data: IntergerStartToken) as Data)
            .andData(integer.digitsInAscii())
            .andData(StructureEndToken)
        return data
    }
    
    /**
     Creates a BEncoded byte string
     */
    open class func encodeByteString(_ byteString: Data) -> Data {
        let numberOfBytes = byteString.count
        return (NSData(data: numberOfBytes.digitsInAscii() as Data) as Data)
            .andData(StringSizeDelimiterToken)
            .andData(byteString)
    }
    
    /**
     Creates a BEncoded byte string with the ascii representation of the string
     
     - throws: BEncoderException.InvalidAscii if the string cannot be represented in ASCII
     */
    open class func encodeString(_ string: String) throws -> Data {
        let asciiString = try self.asciiValue(string)
        let data = (NSData(data: asciiString.count.digitsInAscii() as Data) as Data)
            .andData(StringSizeDelimiterToken)
            .andData(asciiString)
        return data
    }
    
    /**
     Creates a BEncoded list and BEncodes each object in the list
     
     - parameter list: Array of items to be BEncoded and added to the resulting BEncode list
     
     - throws: Exception if any of the objects are not BEncode-able
     
     */
    open class func encodeList(_ list: [Any]) throws -> Data {
        let innerData = try encodeListInnerValues(list)
        return (NSData(data: ListStartToken) as Data).andData(innerData).andData(StructureEndToken)
    }
    
    fileprivate class func encodeListInnerValues(_ list: [Any]) throws -> Data {
        return try list.reduce(NSMutableData()) { (result: NSMutableData, item: Any) throws -> NSMutableData in
            let encodedItem = try self.encode(item)
            result.append(encodedItem)
            return result
        } as Data
    }
    
    /**
     Creates a BEncoded dictionary and BEncodes each value.
     The keys are BEncoded as byte strings
     
     - parameter list: Dictionary of items to be BEncoded and added to the resulting BEncode
     dictionary. Keys should be data which will be BEncoded as a byte string.
     
     - throws: BEncoderException if any of the objects are not BEncode-able
     
     */
    open class func encodeByteStringKeyedDictionary(_ dictionary: [Data:Any]) throws -> Data {
        let innerData = try encodeDictionaryInnerValues(dictionary)
        return (NSData(data: DictinaryStartToken) as Data).andData(innerData).andData(StructureEndToken)
    }
    
    fileprivate class func encodeDictionaryInnerValues(_ dictionary: [Data:Any]) throws -> Data {
        return try dictionary.reduce(NSMutableData(), self.appendKeyValuePairToDictionaryData) as Data
    }
    
    fileprivate class func appendKeyValuePairToDictionaryData(_ data: NSMutableData,
        pair: (key: Data, value: Any)) throws -> NSMutableData {
            data.append(self.encodeByteString(pair.key))
            data.append(try self.encode(pair.value))
            return data
    }
    
    /**
     Creates a BEncoded dictionary and BEncodes each value.
     The keys are BEncoded as strings
     
     - parameter list: Dictionary of items to be BEncoded and added to the resulting BEncode 
                       dictionary. Keys should be ASCII encodeable strings.
     
     - throws: BEncoderException if any of the objects are not BEncode-able.
     BEncoderException.InvalidAscii is thrown if the keys cannot be encoded in ASCII

     */
    open class func encodeDictionary(_ dictionary: [String:Any]) throws -> Data {
        let dictionaryWithEncodedKeys = try self.createDictionaryWithEncodedKeys(dictionary)
        let innerData = try self.encodeDictionaryInnerValues(dictionaryWithEncodedKeys)
        return (NSData(data: DictinaryStartToken) as Data).andData(innerData).andData(StructureEndToken)
    }
    
    fileprivate class func createDictionaryWithEncodedKeys(_ dictionary: [String:Any]) throws -> [Data:Any] {
        var dictionaryWithEncodedKeys: [Data: Any] = [:]
        for (key, value) in dictionary {
            let asciiKey = try self.asciiValue(key)
            dictionaryWithEncodedKeys[asciiKey] = value
        }
        return dictionaryWithEncodedKeys
    }
    
    fileprivate class func asciiValue(_ string: String) throws -> Data {
        do {
            let asciiString = try string.asciiValue()
            return asciiString as Data
        } catch _ {
            throw BEncoderException.invalidAscii
        }
    }

}
