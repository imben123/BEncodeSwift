//
//  NSDataByteStream.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

class NSDataByteStream: ByteStream {
    
    var currentIndex: Data.Index
    fileprivate let data: Data
    fileprivate let length: Int
    
    init(data: Data) {
        self.data = data
        self.length = data.count
        self.currentIndex = data.startIndex
    }
    
    func nextByte() -> Byte? {
        if currentIndex == length {
            return nil
        }
        let result = data[currentIndex]
        currentIndex += 1
        return result
    }
    
    func nextBytes(_ numberOfBytes: Int) -> Data? {
        if !indexIsValid(currentIndex + numberOfBytes) {
            return nil
        }
        let range = Range<Data.Index>(uncheckedBounds: (lower: currentIndex,
                                                        upper: currentIndex.advanced(by: numberOfBytes)))
        let result = data.subdata(in: range)
        currentIndex += numberOfBytes
        return result
    }
    
    func indexIsValid(_ index: Int) -> Bool {
        return index >= 0 && index <= length
    }
    
    func advanceBy(_ numberOfBytes: Int) {
        
        let finalIndex = currentIndex + numberOfBytes
        
        if finalIndex > length {
            currentIndex = length
        } else if finalIndex < 0 {
            currentIndex = 0
        } else {
            currentIndex += numberOfBytes
        }
    }
}
