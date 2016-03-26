//
//  BEncoderDecodeTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BEncode

class BEncoderDecodeTests: XCTestCase {

    // MARK: - Integers
    
    func testCanDecodeInteger() {
        encodeIntegerAndTestDecode(0)
        encodeIntegerAndTestDecode(1)
        encodeIntegerAndTestDecode(255)
        encodeIntegerAndTestDecode(99999)
    }
    
    func encodeIntegerAndTestDecode(integer: Int) {
        let encodedInteger = BEncoder.encodeInteger(integer)
        decodeIntegerAndCompare(encodedInteger, expectedResult: integer)
    }
    
    func decodeIntegerAndCompare(bEncodedInteger: NSData, expectedResult: Int) {
        let result = try! BEncoder.decodeInteger(bEncodedInteger)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testExceptionThrownForIntIfFirstCharacterNotLowerCaseI() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("x5e".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfLastCharacterNotLowerCaseE() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("i5x".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfMissingLastCharacter() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("i5".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfNotValidNumber() {
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            try BEncoder.decodeInteger("ixe".asciiValue())
            try BEncoder.decodeInteger("i1x1e".asciiValue())
        }
    }

    // MARK: - Byte Strings

    func testDecode0ByteString() {
        let input = try! NSMutableData(data: Character("0").asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, NSData())
    }
    
    func testDecode5ByteString() {
        let byteString = NSData(byteArray: [ 1, 2, 3, 255, 0])
        let input = try! NSMutableData(data: Character("5").asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(byteString)
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, byteString)
    }

    func testDecode10ByteString() {
        let byteString = NSData(byteArray: [1,2,3,4,5,6,7,8,9,0])
        let input = try! NSMutableData(data: "10".asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(byteString)
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, byteString)
    }
    
    func testExceptionThrownForStringIfNoDelimiter() {
        let input = try! NSMutableData(data: Character("1").asciiValue())
            .andData(NSData(byteArray: [ 5 ]))
        
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            let _ = try BEncoder.decodeByteString(input)
        }
        
    }
    
    func testExceptionThrownForStringIfStringLengthIsNaN() {
        let input = try! NSMutableData(data: Character("x").asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(NSData(byteArray: [ 5 ]))
        
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            let _ = try BEncoder.decodeByteString(input)
        }
        
    }
    
    func testExceptionThrownForStringIfStringLengthShort() {
        let shortInput = try! NSMutableData(data: Character("5").asciiValue())
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(NSData(byteArray: [ 1, 2, 3, 255]))
        
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            let _ = try BEncoder.decodeByteString(shortInput)        
        }

    }
    
    // MARK: - Strings
    
    func testDecodeEmptyString() {
        let emptyString = ""
        let input = try! BEncoder.encode(emptyString)
        let result = try! BEncoder.decodeString(input)
        XCTAssertEqual(emptyString, result)
    }
    
    func testDecodeString() {
        let string = "A simple test string"
        let input = try! BEncoder.encode(string)
        let result = try! BEncoder.decodeString(input)
        XCTAssertEqual(string, result)
    }
    
    // MARK: - Lists
    
    func testDecodeEmptyList() {
        let input = try! BEncoder.encode([])
        let result = try! BEncoder.decodeList(input)
        XCTAssertEqual(result.count, 0)
    }
    
    func testDecodeListWithInteger() {
        let integer = 5
        let input = try! BEncoder.encode([ integer ])
        let result = try! BEncoder.decodeList(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0] as? Int, integer)
    }
    
    func testDecodeListWith2Integers() {
        let integer1 = 5
        let integer2 = 999
        let input = try! BEncoder.encode([
            integer1,
            integer2
            ])
        let result = try! BEncoder.decodeList(input)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0] as? Int, integer1)
        XCTAssertEqual(result[1] as? Int, integer2)
    }
    
    func testDecodeListWithMixedTypes() {
        let integer = 5
        let byteString = NSData(byteArray: [0,1,2,255])
        let string = "string"
        
        let input = try! BEncoder.encode([
            integer,
            byteString,
            string
            ])
        
        let result = try! BEncoder.decodeList(input)
        let decodedString = String(asciiData: result[2] as! NSData)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0] as? Int, integer)
        XCTAssertEqual(result[1] as? NSData, byteString)
        XCTAssertEqual(decodedString, string)
    }

    func testDecodeListWithNestedLists() {
        let integer = 5
        let byteString = NSData(byteArray: [0,1,2,255])
        let string = "string"
        
        let nestedList = [
            integer,
            byteString,
            string
            ]
        
        let input = try! BEncoder.encode([
            nestedList,
            integer,
            ])
        
        let result = try! BEncoder.decodeList(input)
        let nestedResult = result[0] as! [AnyObject];
        let decodedString = String(asciiData: nestedResult[2] as! NSData)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[1] as? Int, integer)
        XCTAssertEqual(nestedResult.count, 3)
        XCTAssertEqual(nestedResult[0] as? Int, integer)
        XCTAssertEqual(nestedResult[1] as? NSData, byteString)
        XCTAssertEqual(decodedString, string)
    }
    
    func testExceptionThrownForListIfFirstCharacterNotLowerCaseL() {
        
        let encodedList = NSData(byteArray: [
            
            120,                                // x
            105, 49, 50, 51, 101,               // i123e
            101                                 // e

            ])
        
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            let test = try BEncoder.decodeList(encodedList)
            print(test)
        }
        
    }
    
    func testExceptionThrownForListIfLastCharacterNotLowerCaseE() {
        
        let encodedList = NSData(byteArray: [
            108,                                // l
            105, 49, 50, 51, 101,               // i123e

            ])
        
        assertExceptionThrown(BEncoderException.InvalidBEncode) {
            let _ = try BEncoder.decodeList(encodedList)
        }
        
    }
    
    // MARK: - Dictionaries
    
    func testDecodeEmptyDictionary() {
        let emptyDictionary: [NSData:NSData] = [:]
        let input = try! BEncoder.encode(emptyDictionary)
        let result = try! BEncoder.decodeDictionary(input)
        XCTAssertEqual(result.count, 0)
    }
    
    func testDecodeDictionaryWithInteger() {
        let key = try! "key".asciiValue()
        let integer = 5
        let input = try! BEncoder.encode([ key : integer ])
        let result = try! BEncoder.decodeDictionary(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[key] as? Int, integer)
    }
    
    func testDecodeDictionaryWithMultipleIntegers() {
        let key1 = try! "key1".asciiValue()
        let integer1 = 5
        
        let key2 = try! "key2".asciiValue()
        let integer2 = 6
        
        let input = try! BEncoder.encode([
            key1 : integer1,
            key2 : integer2
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[key1] as? Int, integer1)
        XCTAssertEqual(result[key2] as? Int, integer2)
    }
    
    func testDecodeDictionaryWithMultipleTypes() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = NSData(byteArray: [0,1,2,255])
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? NSData, byteString)
    }
    
    func testDecodeDictionaryWithDictionary() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = NSData(byteArray: [0,1,2,255])
        
        let key3 = try! "key3".asciiValue()
        let dictionary = [
            key1 : integer,
            key2 : byteString
            ]
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key3 : dictionary,
            key2 : byteString
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        let decodedDictionary = result[key3] as! [NSData:AnyObject]
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? NSData, byteString)
        XCTAssertEqual(decodedDictionary.count, 2)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? NSData, byteString)
    }
    
    // MARK: List and Dictionary combinations
    
    func testDecodeDictionaryWithList() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = NSData(byteArray: [0,1,2,255])
        
        let key3 = try! "key3".asciiValue()
        let list = [ byteString, integer ]
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString,
            key3 : list,
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        let decodedList = result[key3] as! [AnyObject]
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? NSData, byteString)
        XCTAssertEqual(decodedList.count, 2)
        XCTAssertEqual(decodedList[0] as? NSData, byteString)
        XCTAssertEqual(decodedList[1] as? Int, integer)
    }
    
    func testDecodeListWithDictionary() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = NSData(byteArray: [0,1,2,255])
        
        let dictionary = [
            key1 : integer,
            key2 : byteString
            ]
        
        let list = [
            integer,
            dictionary,
            byteString
        ]
        
        let input = try! BEncoder.encode(list)
        let result = try! BEncoder.decodeList(input)
        let decodedDictionary = result[1] as! [NSData:AnyObject]
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0] as? Int, integer)
        XCTAssertEqual(decodedDictionary.count, 2)
        XCTAssertEqual(result[2] as? NSData, byteString)
        XCTAssertEqual(decodedDictionary[key1] as? Int, integer)
        XCTAssertEqual(decodedDictionary[key2] as? NSData, byteString)
    }
    
    func testDecodeDictionaryKeysOnly() {
        let key1 = "key1"
        let integer = 5
        let encodedInteger = try! BEncoder.encode(integer)
        
        let key2 = "key2"
        let byteString = NSData(byteArray: [0,5,255])
        let encodedByteString = try! BEncoder.encode(byteString)
        
        let key3 = "key3"
        let list = [integer, byteString]
        let encodedList = try! BEncoder.encode(list)
        
        let key4 = "key4"
        let dictionary = [key1:integer, key2:byteString]
        let encodedDictionary = try! BEncoder.encode(dictionary)

        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString,
            key3 : list,
            key4 : dictionary,
            ])
        
        let result = try! BEncoder.decodeDictionaryKeysOnly(input)
        XCTAssertEqual(result[key1], encodedInteger)
        XCTAssertEqual(result[key2], encodedByteString)
        XCTAssertEqual(result[key3], encodedList)
        XCTAssertEqual(result[key4], encodedDictionary)
    }
}
