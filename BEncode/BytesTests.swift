//
//  BytesTests.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import XCTest
@testable import BEncode

class BytesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEncode8BitInteger() {
        let integer: UInt8 = 123
        let data = integer.toData()
        
        let pointer = (data as NSData).bytes.bindMemory(to: Byte.self, capacity: data.count)
        let value: UInt8 = pointer.pointee
        XCTAssertEqual(data.count, 1)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode16BitIntegerBigEndian() {
        let integer: UInt16 = 12345
        let data = integer.toData()
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt16.self, capacity: data.count)
        let value: UInt16 = pointer.pointee.bigEndian
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode16BitIntegerLittleEndian() {
        let integer: UInt16 = 12345
        let data = integer.toData(bigEndian: false)
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt16.self, capacity: data.count)
        let value: UInt16 = pointer.pointee
        XCTAssertEqual(data.count, 2)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode32BitIntegerBigEndian() {
        let integer: UInt32 = 1234567891
        let data = integer.toData()
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt32.self, capacity: data.count)
        let value: UInt32 = pointer.pointee.bigEndian
        XCTAssertEqual(data.count, 4)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode32BitIntegerLittleEndian() {
        let integer: UInt32 = 1234567891
        let data = integer.toData(bigEndian: false)
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt32.self, capacity: data.count)
        let value: UInt32 = pointer.pointee
        XCTAssertEqual(data.count, 4)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode64BitIntegerBigEndian() {
        let integer: UInt64 = 12345678912345678912
        let data = integer.toData()
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt64.self, capacity: data.count)
        let value: UInt64 = pointer.pointee.bigEndian
        XCTAssertEqual(data.count, 8)
        XCTAssertEqual(value, integer)
    }
    
    func testEncode64BitIntegerLittleEndian() {
        let integer: UInt64 = 12345678912345678912
        let data = integer.toData(bigEndian: false)
        
        let pointer = (data as NSData).bytes.bindMemory(to: UInt64.self, capacity: data.count)
        let value: UInt64 = pointer.pointee
        XCTAssertEqual(data.count, 8)
        XCTAssertEqual(value, integer)
    }
    
    func testIntegerFromData() {
        doTestFor8BitIntFromData(0)
        doTestFor8BitIntFromData(5)
        doTestFor8BitIntFromData(UInt8.max)
        
        doTestFor16BitIntFromData(0)
        doTestFor16BitIntFromData(5)
        doTestFor16BitIntFromData(UInt16.max)
        
        doTestFor32BitIntFromData(0)
        doTestFor32BitIntFromData(5)
        doTestFor32BitIntFromData(UInt32.max)
        
        doTestFor64BitIntFromData(0)
        doTestFor64BitIntFromData(5)
        doTestFor64BitIntFromData(UInt64.max)
    }
    
    func doTestFor8BitIntFromData(_ integer: UInt8) {
        let data = integer.toData()
        let result = data.toUInt8()
        XCTAssertEqual(result, integer)
    }
    
    func doTestFor16BitIntFromData(_ integer: UInt16) {
        let data = integer.toData()
        let result = data.toUInt16()
        XCTAssertEqual(result, integer)
        
        let dataLittleEndian = integer.toData(bigEndian: false)
        let resultLittleEndian = dataLittleEndian.toUInt16(bigEndian: false)
        XCTAssertEqual(resultLittleEndian, integer)
    }
    
    func doTestFor32BitIntFromData(_ integer: UInt32) {
        let data = integer.toData()
        let result = data.toUInt32()
        XCTAssertEqual(result, integer)
        
        let dataLittleEndian = integer.toData(bigEndian: false)
        let resultLittleEndian = dataLittleEndian.toUInt32(bigEndian: false)
        XCTAssertEqual(resultLittleEndian, integer)
    }
    
    func doTestFor64BitIntFromData(_ integer: UInt64) {
        let data = integer.toData()
        let result = data.toUInt64()
        XCTAssertEqual(result, integer)
        
        let dataLittleEndian = integer.toData(bigEndian: false)
        let resultLittleEndian = dataLittleEndian.toUInt64(bigEndian: false)
        XCTAssertEqual(resultLittleEndian, integer)
    }
}
