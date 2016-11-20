//
//  BEncoderTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BEncode

class BEncoderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Integers
    
    func testEncodeInteger() {
        doTestEncodeInteger(0)
        doTestEncodeInteger(1)
        doTestEncodeInteger(5)
        doTestEncodeInteger(123)
        doTestEncodeInteger(9999)
    }
    
    func doTestEncodeInteger(_ integer: Int) {
        let data = try! BEncoder.encode(integer)
        let string = String(data: data, encoding: String.Encoding.ascii)
        XCTAssertEqual(string, "i\(integer)e")
    }
    
    // MARK: - Byte Strings
    
    func testEncodeEmptyByteString() {
        let data = try! BEncoder.encode(Data())
        let expectedResult = Data(bytes: [48, 58])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeByteString() {
        let byteString = Data(bytes: [ 1, 2, 3, 255, 0])
        let data = try! BEncoder.encode(byteString)
        let expectedResult = try! (NSData(data: Character("5").asciiValue()) as Data)
            .andData(BEncoder.StringSizeDelimiterToken)
            .andData(byteString)
        XCTAssertEqual(data, expectedResult)
    }
    
    // MARK: - Strings
    
    func testEncodeEmptyString() {
        let data = try! BEncoder.encode("")
        let expectedResult = Data(bytes: [48, 58])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeString() {
        let data = try! BEncoder.encode("foobar")
        let expectedResult = Data(bytes: [54, 58, 102, 111, 111, 98, 97, 114])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeNonAsciiStringThrows() {
        assertExceptionThrown(BEncoderException.invalidAscii) {
            let _ = try BEncoder.encode("🙂")
        }
    }
    
    // MARK: - Lists
    
    func testEncodeEmptyList() {
        let data = try! BEncoder.encode([])
        let expectedResult = Data(bytes: [108, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeListWithOneObject() {
        let integer = 123
        let data = try! BEncoder.encode([integer])
        let expectedResult = Data(bytes: [108, 105, 49, 50, 51, 101, 101])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeSimpleList() {
        let exampleData = self.exampleListAndExpectedValues()
        let bEncodedData = try! BEncoder.encode(exampleData.list)
        let expectedResult = Data(bytes: exampleData.expectedValues)
        
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeListWithNestedDictionary() {
        
        let input = [
            123,
            [ "foo": "bar" ],
            "baz"
        ] as [Any]
        
        let expectedResultArray: [UInt8] = [
            108,                    // l
            
            105, 49, 50, 51, 101,   // i123e
            
            100,                    // d
            51, 58, 102, 111, 111,  // 3:foo
            51, 58, 98,  97,  114,  // 3:bar
            101,                    // e
            
            51, 58, 98,  97,  122,  // 3:baz
            
            101                     // e
        ]
        
        let result = try! BEncoder.encode(input)
        let expectedResult = Data(bytes: expectedResultArray)
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - Dictionaries
    
    func testEncodeEmptyDictionary() {
        let data = try! BEncoder.encode(Dictionary<Data, Data>())
        let expectedResult = Data(bytes: [100, 101]) // de
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeDictionaryWithOneValue() {
        let data = try! BEncoder.encode([
            Data(bytes: [1]) : 1
            ])
        let expectedResult = Data(bytes:
            [
                100,            // d
                49, 58, 1,      // 1:\0x1
                105, 49, 101,   // i1e
                101             // e
            ])
        XCTAssertEqual(data, expectedResult)
    }
    
    func testEncodeSimpleDictionary() {
        let exampleDictionary = exampleDictionaryAndExpectedValues()
        let bEncodedData = try! BEncoder.encode(exampleDictionary.dictionary)
        let expectedResult = Data(bytes: exampleDictionary.expectedValues)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithStringKeys() {
        let bEncodedDataDictionary = [
            "foo" : "bar",
            "baz" : Data(bytes: [0,7,255]),
        ] as [String : Any]
        
        var expectedResultArray: [UInt8] = [100]                                 // d
        
        expectedResultArray.append(contentsOf: [51, 58, 102, 111, 111])          // 3:foo
        expectedResultArray.append(contentsOf: [51, 58, 98,  97,  114])          // 3:bar
        
        expectedResultArray.append(contentsOf: [51, 58, 98,  97,  122])          // 3:baz
        expectedResultArray.append(contentsOf: [51, 58, 0,   7,   255])          // 3:\0x00\0x07\0xFF
        
        expectedResultArray.append(101)                                          // e
        
        let bEncodedData = try! BEncoder.encode(bEncodedDataDictionary)
        let expectedResult = Data(bytes: expectedResultArray)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithNonAsciiStringKeysThrows() {
        
        let bEncodedDataDictionary = [
            "🙂"  : try! BEncoder.encode("bar"),
            "baz" : try! BEncoder.encode(Data(bytes: [0,7,255])),
        ]
        
        assertExceptionThrown(BEncoderException.invalidAscii) {
            try BEncoder.encodeDictionary(bEncodedDataDictionary)
        }

    }
    
    func testEncodeDictionaryWithList() {
        
        // Order is not maintained by dictionary so this test can fail due to order change
        
        let exampleList = self.exampleListAndExpectedValues()
        let exampleDictionary = self.exampleDictionaryAndExpectedValues()
        
        let bEncodedDataDictionary = [
            Data(bytes: [1])                  : 1,
            try! "foo".asciiValue()                 : "bar",
            try! "baz".asciiValue()                 : Data(bytes: [0,7,255]),
            Data(bytes: [0])                  : exampleList.list,
            Data(bytes: [255, 255, 255, 255]) : exampleDictionary.dictionary
        ] as [Data : Any] as [Data : Any]
        
        var expectedResultArray: [UInt8] = [100]                                 // d
        
        expectedResultArray.append(contentsOf: [51, 58, 98,  97,  122])           // 3:baz
        expectedResultArray.append(contentsOf: [51, 58, 0,   7,   255])           // 3:\0x00\0x07\0xFF
        
        expectedResultArray.append(contentsOf: [52, 58, 255, 255, 255, 255])      // 4:\0xFF\0xFF\0xFF\0xFF
        expectedResultArray.append(contentsOf: exampleDictionary.expectedValues)  // <bEncoded values>
        
        expectedResultArray.append(contentsOf: [49, 58, 0])                       // 1:\0x0
        expectedResultArray.append(contentsOf: exampleList.expectedValues)        // <bEncoded values>
        
        expectedResultArray.append(contentsOf: [49, 58, 1])                       // 1:\0x1
        expectedResultArray.append(contentsOf: [105, 49, 101])                    // i1e
        
        expectedResultArray.append(contentsOf: [51, 58, 102, 111, 111])           // 3:foo
        expectedResultArray.append(contentsOf: [51, 58, 98,  97,  114])           // 3:bar
        
        expectedResultArray.append(101)                                         // e
        
        let bEncodedData = try! BEncoder.encode(bEncodedDataDictionary)
        let expectedResult = Data(bytes: expectedResultArray)
        XCTAssertEqual(bEncodedData, expectedResult)
    }
    
    func testEncodeDictionaryWithListAndStringKeys() {
        let input = [
            "hello": ["world", 123],
            "foo": "bar",
            "baz": 123,
        ] as [String : Any]
        
        
        let expectedResultArray: [UInt8] = [
            100,                              // d
            
            53, 58, 104, 101, 108, 108, 111,  // 5:hello
            108,                              // l
            53, 58, 119, 111, 114, 108, 100,  // 5:world
            105, 49, 50, 51, 101,             // i123e
            101,                              // e
            
            51, 58, 102, 111, 111,            // 3:foo
            51, 58, 98,  97,  114,            // 3:bar
            
            51, 58, 98,  97,  122,            // 3:baz
            105, 49, 50, 51, 101,             // i123e
            
            101                               // e
        ]
        
        let result = try! BEncoder.encode(input)
        let expectedData = Data(bytes: expectedResultArray)
        XCTAssertEqual(result, expectedData)
    }

    // MARK: - Example inputs
    
    fileprivate func exampleListAndExpectedValues() -> (list: [Any], expectedValues: [UInt8]) {
        
        let bEncodedDataArray = [
            123,
            0,
            999,
            "foobar",
            "999",
            Data(bytes: [0, 1, 2, 3, 255])
        ] as [Any]
        
        let expectedResultArray: [UInt8] = [
            108,                                // l
            105, 49, 50, 51, 101,               // i123e
            105, 48, 101,                       // i0e
            105, 57, 57, 57, 101,               // i999e
            54, 58, 102, 111, 111, 98, 97, 114, // 6:foobar
            51, 58, 57, 57, 57,                 // 3:999
            53, 58, 0, 1, 2, 3, 255,            // 5:\0x00\0x01\0x02\0x03\0xFF
            101                                 // e
        ]
        
        return (bEncodedDataArray, expectedResultArray)
    }
    
    fileprivate func exampleDictionaryAndExpectedValues() -> (dictionary: [Data:Any], expectedValues: [UInt8]) {
        
        // Order is not maintained by dictionary so this test can fail due to order change
        
        let bEncodedDataDictionary = [
            Data(bytes: [1])                  : 1,
            try! "baz".asciiValue()           : Data(bytes: [0,7,255]),
            try! "foo".asciiValue()           : "bar",
        ] as [Data : Any]
        
        let expectedResultArray: [UInt8] = [
            100,                    // d
            
            51, 58, 98,  97,  122,  // 3:baz
            51, 58, 0,   7,   255,  // 3:\0x00\0x07\0xFF
            
            49, 58, 1,              // 1:\0x1
            105, 49, 101,           // i1e
            
            51, 58, 102, 111, 111,  // 3:foo
            51, 58, 98,  97,  114,  // 3:bar
            
            101                     // e
        ]
        
        return (bEncodedDataDictionary, expectedResultArray)
    }
    
    // MARK: - 
    
    func testExceptionThrownIfTryToEncodeObjectNotRepresentableInBEncode() {
        assertExceptionThrown(BEncoderException.unrepresentableObject) {
            let _ = try BEncoder.encode(UIView())
        }
    }
    
}
