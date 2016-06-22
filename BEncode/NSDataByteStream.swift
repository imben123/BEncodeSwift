//
//  NSDataByteStream.swift
//  BitTorrent
//
//  Created by Ben Davis on 12/03/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

class NSDataByteStream: ByteStream {
	var currentIndex = 0
	private let data: NSData
	private let length: Int
	private var pointer: UnsafePointer<UInt8>

	init(data: NSData) {
		self.data = data
		self.pointer = UnsafePointer<UInt8>(data.bytes)
		self.length = data.length
	}

	func nextByte() -> UInt8? {
		if self.currentIndex == self.length {
			return nil
		}

		let result = self.pointer.memory
		self.advancePointer(1)
		return result
	}

	private func advancePointer(numberOfBytes: Int) {
		self.pointer = self.pointer.advancedBy(numberOfBytes)
		self.currentIndex += numberOfBytes
	}

	func nextBytes(numberOfBytes: Int) -> NSData? {
		if !self.indexIsValid(self.currentIndex + numberOfBytes) {
			return nil
		}

		let result = self.data.subdataWithRange(NSMakeRange(self.currentIndex, numberOfBytes))
		self.advancePointer(numberOfBytes)
		return result
	}

	func indexIsValid(index: Int) -> Bool {
		return index >= 0 && index <= self.length
	}

	func advanceBy(numberOfBytes: Int) {
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