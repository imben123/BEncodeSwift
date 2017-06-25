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
    
    func encodeIntegerAndTestDecode(_ integer: Int) {
        let encodedInteger = BEncoder.encodeInteger(integer)
        decodeIntegerAndCompare(encodedInteger, expectedResult: integer)
    }
    
    func decodeIntegerAndCompare(_ bEncodedInteger: Data, expectedResult: Int) {
        let result = try! BEncoder.decodeInteger(bEncodedInteger)
        XCTAssertEqual(result, expectedResult)
    }
    
    func testExceptionThrownForIntIfFirstCharacterNotLowerCaseI() {
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeInteger("x5e".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfLastCharacterNotLowerCaseE() {
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeInteger("i5x".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfMissingLastCharacter() {
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeInteger("i5".asciiValue())
        }
    }
    
    func testExceptionThrownForIntIfNotValidNumber() {
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeInteger("ixe".asciiValue())
            let _ = try BEncoder.decodeInteger("i1x1e".asciiValue())
        }
    }

    // MARK: - Byte Strings

    func testDecode0ByteString() {
        let input = try! Character("0").asciiValue() + BEncoder.StringSizeDelimiterToken
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, Data())
    }
    
    func testDecode5ByteString() {
        let byteString = Data(bytes: [ 1, 2, 3, 255, 0])
        let input = try! Character("5").asciiValue() + BEncoder.StringSizeDelimiterToken + byteString
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, byteString)
    }

    func testDecode10ByteString() {
        let byteString = Data(bytes: [1,2,3,4,5,6,7,8,9,0])
        let input = try! "10".asciiValue() + BEncoder.StringSizeDelimiterToken + byteString
        
        let result = try! BEncoder.decodeByteString(input)
        
        XCTAssertEqual(result, byteString)
    }
    
    func testExceptionThrownForStringIfNoDelimiter() {
        let input = try! Character("1").asciiValue() + Data(bytes: [ 5 ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeByteString(input)
        }
        
    }
    
    func testExceptionThrownForStringIfStringLengthIsNaN() {
        let input = try! Character("x").asciiValue() + BEncoder.StringSizeDelimiterToken + Data(bytes: [ 5 ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeByteString(input)
        }
        
    }
    
    func testExceptionThrownForStringIfStringLengthShort() {
        let shortInput = try! Character("5").asciiValue() + BEncoder.StringSizeDelimiterToken + Data(bytes: [ 1, 2, 3, 255])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
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
        let byteString = Data(bytes: [0,1,2,255])
        let string = "string"
        
        let input = try! BEncoder.encode([
            integer,
            byteString,
            string
            ])
        
        let result = try! BEncoder.decodeList(input)
        let decodedString = String(asciiData: result[2] as? Data)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0] as? Int, integer)
        XCTAssertEqual(result[1] as? Data, byteString)
        XCTAssertEqual(decodedString, string)
    }

    func testDecodeListWithNestedLists() {
        let integer = 5
        let byteString = Data(bytes: [0,1,2,255])
        let string = "string"
        
        let nestedList: [Any] = [
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
        let decodedString = String(asciiData: nestedResult[2] as? Data)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[1] as? Int, integer)
        XCTAssertEqual(nestedResult.count, 3)
        XCTAssertEqual(nestedResult[0] as? Int, integer)
        XCTAssertEqual(nestedResult[1] as? Data, byteString)
        XCTAssertEqual(decodedString, string)
    }
    
    func testExceptionThrownForListIfFirstCharacterNotLowerCaseL() {
        
        let encodedList = Data(bytes: [
            
            120,                                // x
            105, 49, 50, 51, 101,               // i123e
            101                                 // e

            ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeList(encodedList)
        }
        
    }
    
    func testExceptionThrownForListIfLastCharacterNotLowerCaseE() {
        
        let encodedList = Data(bytes: [
            108,                                // l
            105, 49, 50, 51, 101,               // i123e

            ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeList(encodedList)
        }
        
    }
    
    // MARK: - Dictionaries
    
    func testDecodeEmptyDictionary() {
        let emptyDictionary: [Data:Data] = [:]
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
        let byteString = Data(bytes: [0,1,2,255])
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? Data, byteString)
    }
    
    func testDecodeDictionaryWithDictionary() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = Data(bytes: [0,1,2,255])
        
        let key3 = try! "key3".asciiValue()
        let dictionary: [Data:Any] = [
            key1 : integer,
            key2 : byteString
            ]
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key3 : dictionary,
            key2 : byteString
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        let decodedDictionary = result[key3] as! [Data:AnyObject]
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? Data, byteString)
        XCTAssertEqual(decodedDictionary.count, 2)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? Data, byteString)
    }
    
    func testExceptionThrownForDictionaryIfFirstCharacterNotLowerCaseD() {
        
        let encodedDictionary = Data(bytes: [
            
            120,                                // x
            51, 58, 107, 101, 121,              // 3:key
            105, 49, 50, 51, 101,               // i123e
            101                                 // e
            
            ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeDictionary(encodedDictionary)
        }
    }
    
    func testExceptionThrownForDictionaryIfLastCharacterNotLowerCaseE() {
        
        let encodedDictionary = Data(bytes: [
            
            100,                                // d
            51, 58, 107, 101, 121,              // 3:key
            105, 49, 50, 51, 101,               // i123e
            
            ])
        
        assertExceptionThrown(BEncoderException.invalidBEncode) {
            let _ = try BEncoder.decodeDictionary(encodedDictionary)
        }
    }
    
    // MARK: List and Dictionary combinations
    
    func testDecodeDictionaryWithList() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = Data(bytes: [0,1,2,255])
        
        let key3 = try! "key3".asciiValue()
        let list: [Any] = [ byteString, integer ]
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString,
            key3 : list,
            ])
        
        let result = try! BEncoder.decodeDictionary(input)
        let decodedList = result[key3] as! [AnyObject]
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[key1] as? Int, integer)
        XCTAssertEqual(result[key2] as? Data, byteString)
        XCTAssertEqual(decodedList.count, 2)
        XCTAssertEqual(decodedList[0] as? Data, byteString)
        XCTAssertEqual(decodedList[1] as? Int, integer)
    }
    
    func testDecodeListWithDictionary() {
        let key1 = try! "key1".asciiValue()
        let integer = 5
        
        let key2 = try! "key2".asciiValue()
        let byteString = Data(bytes: [0,1,2,255])
        
        let dictionary: [Data:Any] = [
            key1 : integer,
            key2 : byteString
            ]
        
        let list: [Any] = [
            integer,
            dictionary,
            byteString
        ]
        
        let input = try! BEncoder.encode(list)
        let result = try! BEncoder.decodeList(input)
        let decodedDictionary = result[1] as! [Data:AnyObject]
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0] as? Int, integer)
        XCTAssertEqual(decodedDictionary.count, 2)
        XCTAssertEqual(result[2] as? Data, byteString)
        XCTAssertEqual(decodedDictionary[key1] as? Int, integer)
        XCTAssertEqual(decodedDictionary[key2] as? Data, byteString)
    }
    
    func testDecodeDictionaryKeysOnly() {
        let key1 = "key1"
        let integer = 5
        let encodedInteger = try! BEncoder.encode(integer)
        
        let key2 = "key2"
        let byteString = Data(bytes: [0,5,255])
        let encodedByteString = try! BEncoder.encode(byteString)
        
        let key3 = "key3"
        let list: [Any] = [integer, byteString]
        let encodedList = try! BEncoder.encode(list)
        
        let key4 = "key4"
        let dictionary: [String : Any] = [key1:integer, key2:byteString]
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
    
    func testDecodeDictionaryWithStringKeys() {
        let key1 = "key1"
        let integer = 5
        
        let key2 = "key2"
        let byteString = Data(bytes: [0,5,255])
        
        let key3 = "key3"
        let dictionary: [String : Any] = [key1:integer, key2:byteString]
        
        let key4 = "key4"
        let list: [Any] = [integer, byteString, dictionary]
        
        let input = try! BEncoder.encode([
            key1 : integer,
            key2 : byteString,
            key3 : dictionary,
            key4 : list,
            ])
        
        let result = try! BEncoder.decode(input, decodeDictionariesWithStringKeys: true) as! [ String : Any ]
        let decodedDictionary = result[key3] as! [String: Any]
        let decodedList = result[key4] as! [Any]
        XCTAssertEqual(result[key1] as! Int, integer)
        XCTAssertEqual(result[key2] as! Data, byteString)
        XCTAssertEqual(decodedList, list)
        XCTAssertEqual(decodedDictionary, dictionary)
    }
}
