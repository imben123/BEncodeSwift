//
//  Bytes.swift
//  BitTorrent
//
//  Created by Ben Davis on 02/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public extension NSData {
	convenience init(byteArray: [UInt8]) {
		self.init(bytes: UnsafePointer<UInt8>(byteArray), length: byteArray.count)
	}

	func dataByAppendingData(data: NSData) -> NSData {
		let result = self.mutableCopy() as! NSMutableData
		result.appendData(data)
		return result
	}

	subscript(index: Int) -> UInt8? {
		get {
			if index < 0 || index >= self.length {
				return nil
			}

			return UnsafePointer<UInt8>(self.bytes.advancedBy(index)).memory
		}
	}

	subscript(range: Range<Int>) -> NSData? {
		get {
			let location = range.startIndex
			let length = range.endIndex - range.startIndex

			if range.startIndex < 0 || range.endIndex >= self.length {
				return nil
			}
			
			return self.subdataWithRange(NSMakeRange(location, length))
		}
	}
}

public extension NSMutableData {
	func andData(data: NSData) -> NSMutableData {
		self.appendData(data)
		return self
	}
}

public extension UInt8 {
	func toData() -> NSData {
		return NSData(byteArray: [self])
	}

	static func fromData(byte: NSData) -> UInt8 {
		return UnsafePointer<UInt8>(byte.bytes).memory
	}
}