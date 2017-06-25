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
    func toUInt8() -> UInt8 {
        return self[0]
    }
}

public extension UInt8 {
    
    func toData() -> Data {
        return Data(bytes: [self])
    }
    
    init(data: Data) {
        self = data.toUInt8()
    }
}
