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
    fileprivate var pointer: UnsafePointer<Byte>
    
    init(data: Data) {
        self.data = data
        self.pointer = (data as NSData).bytes.bindMemory(to: Byte.self, capacity: data.count)
        self.length = data.count
        self.currentIndex = data.startIndex
    }
    
    func nextByte() -> Byte? {
        if self.currentIndex == self.length {
            return nil
        }
        let result = self.pointer.pointee
        self.advancePointer(1)
        return result
    }
    
    fileprivate func advancePointer(_ numberOfBytes: Int) {
        self.pointer = self.pointer.advanced(by: numberOfBytes)
        self.currentIndex += numberOfBytes
    }
    
    func nextBytes(_ numberOfBytes: Int) -> Data? {
        if !self.indexIsValid(self.currentIndex + numberOfBytes) {
            return nil
        }
        let range = Range<Data.Index>(uncheckedBounds: (lower: self.currentIndex,
                                                        upper: self.currentIndex.advanced(by: numberOfBytes)))
        let result = self.data.subdata(in: range)
        self.advancePointer(numberOfBytes)
        return result
    }
    
    func indexIsValid(_ index: Int) -> Bool {
        return index >= 0 && index <= self.length
    }
    
    func advanceBy(_ numberOfBytes: Int) {
        
        let finalIndex = self.currentIndex + numberOfBytes
        
        if finalIndex > self.length {
            self.advancePointer(self.length - self.currentIndex)
        } else if finalIndex < 0 {
            self.advancePointer(-self.currentIndex)
        } else {
            self.advancePointer(numberOfBytes)
        }
        
    }
    
}
