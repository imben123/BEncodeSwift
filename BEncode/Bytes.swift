//
//  Bytes.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public typealias Byte = UInt8

public extension Data {
    
    func dataByAppendingData(_ data: Data) -> Data {
        let result = (self as NSData).mutableCopy() as! NSMutableData
        result.append(data)
        return result as Data
    }
    
    func andData(_ data: Data) -> Data {
        return self.dataByAppendingData(data)
    }
    
}

public extension UInt8 {
    
    func toData() -> Data {
        return Data(bytes: [self])
    }
    
    static func fromData(_ byte: Data) -> UInt8 {
        let pointer = (byte as NSData).bytes.bindMemory(to: UInt8.self, capacity: byte.count)
        return pointer.pointee
    }
    
}
