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
        XCTAssertEqual(value, integer)
    }
    
    func testIntegerFromData() {
        doTestForIntegerFromData(0)
        doTestForIntegerFromData(5)
        doTestForIntegerFromData(UInt8.max)
    }
    
    func doTestForIntegerFromData(_ integer: UInt8) {
        let data = integer.toData()
        let result = data.toUInt8()
        XCTAssertEqual(result, integer)
    }
}
