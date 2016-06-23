//
//  BEncoder+decode.swift
//  BitTorrent
//
//  Created by Ben Davis on 09/01/2016.
//  Copyright © 2016 Ben Davis. All rights reserved.
//

import Foundation

public extension BEncoder {
	/**
	Decodes BEncoded data to swift objects

	- parameter byteStream: Any class implementing the ByteStream protocol that will feed the
	decoder sequential bytes from BEncoded data.

	- throws: BEncoderException.InvalidBEncode if unable to decode the data

	- returns: An Int, String, NSData, Array or Dictionary depending on the type of the
	BEncoded data
	*/
	class func decode(byteStream: ByteStream) throws -> AnyObject {
		return try self.decode(byteStream, decodeDictionariesWithStringKeys: false)
	}

	class func decode(byteStream: ByteStream, decodeDictionariesWithStringKeys: Bool) throws -> AnyObject {
		let firstByte = byteStream.nextByte()
		byteStream.advanceBy(-1)

		if firstByte == ascii_i {
			return try self.decodeInteger(byteStream)
		} else if firstByte == ascii_l {
			return try self.decodeList(byteStream, decodeDictionariesWithStringKeys: decodeDictionariesWithStringKeys)
		} else if firstByte == ascii_d {
			if decodeDictionariesWithStringKeys {
				return try self.decodeStringKeyedDictionary(byteStream)
			} else {
				return try self.decodeDictionary(byteStream)
			}
		} else {
			return try self.decodeByteString(byteStream)
		}
	}

	/**
	Convenience method to decode NSData.
	*/
	class func decode(data: NSData) throws -> AnyObject {
		return try self.decode(NSDataByteStream(data: data))
	}

	class func decode(data: NSData, decodeDictionariesWithStringKeys stringKeys: Bool) throws -> AnyObject {
		return try self.decode(NSDataByteStream(data: data), decodeDictionariesWithStringKeys: stringKeys)
	}

	class func decodeInteger(data: NSData) throws -> Int {
		return try self.decodeInteger(NSDataByteStream(data: data))
	}

	class func decodeInteger(byteStream: ByteStream) throws -> Int {
		try self.testFirstByte(byteStream, expectedFirstByte: ascii_i)

		return try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_e)
	}

	private class func buildAsciiIntegerFromStream(byteStream: ByteStream, terminator: UInt8) throws -> Int {
		var currentDigit = byteStream.nextByte()
		var result: Int = 0

		while currentDigit != terminator {
			result = try self.appendNextDigitIfNotNil(result, currentDigit: currentDigit)
			currentDigit = byteStream.nextByte()
		}

		return result
	}

	private class func testFirstByte(byteStream: ByteStream, expectedFirstByte: UInt8) throws {
		if byteStream.nextByte() != expectedFirstByte {
			throw BEncoderException.InvalidBEncode
		}
	}

	private class func appendNextDigitIfNotNil(integer: Int, currentDigit: UInt8?) throws -> Int {
		if let digit = currentDigit {
			return try self.appendAsciiDigitToInteger(integer, digit: digit)
		} else {
			throw BEncoderException.InvalidBEncode
		}
	}

	private class func appendAsciiDigitToInteger(integer: Int, digit: UInt8) throws -> Int {
		do {
			return try integer.appendAsciiDigit(digit)
		} catch let e as AsciiError where e == AsciiError.Invalid {
			throw BEncoderException.InvalidBEncode
		}
	}

	class func decodeByteString(data: NSData) throws -> NSData {
		return try self.decodeByteString(NSDataByteStream(data: data))
	}

	class func decodeByteString(byteStream: ByteStream) throws -> NSData {
		let numberOfBytes = try self.buildAsciiIntegerFromStream(byteStream, terminator: ascii_colon)

		if !byteStream.indexIsValid(byteStream.currentIndex + numberOfBytes) {
			throw BEncoderException.InvalidBEncode
		}

		return byteStream.nextBytes(numberOfBytes)!
	}

	class func decodeString(data: NSData) throws -> String {
		return try self.decodeString(NSDataByteStream(data: data));
	}

	class func decodeString(byteStream: ByteStream) throws -> String {
		let data = try self.decodeByteString(byteStream)

		guard let result = String(asciiData: data) else {
			throw BEncoderException.InvalidBEncode
		}

		return result
	}

	class func decodeList(data: NSData) throws -> [AnyObject] {
		return try self.decodeList(NSDataByteStream(data: data))
	}

	class func decodeList(byteStream: ByteStream) throws -> [AnyObject] {
		return try self.decodeList(byteStream, decodeDictionariesWithStringKeys: false)
	}

	class func decodeList(data: NSData, decodeDictionariesWithStringKeys stringKeys: Bool) throws -> [AnyObject] {
		return try self.decodeList(NSDataByteStream(data: data), decodeDictionariesWithStringKeys:stringKeys)
	}

	class func decodeList(byteStream: ByteStream,
	                             decodeDictionariesWithStringKeys stringKeys: Bool) throws -> [AnyObject] {
		var result: [AnyObject] = []
		let firstByte = byteStream.nextByte()

		if firstByte != ascii_l {
			throw BEncoderException.InvalidBEncode
		}

		var currentByte = byteStream.nextByte()

		while currentByte != ascii_e {
			byteStream.advanceBy(-1)
			let object = try self.decode(byteStream, decodeDictionariesWithStringKeys: stringKeys)
			result.append(object)
			currentByte = byteStream.nextByte()
		}

		return result
	}

	class func decodeDictionary(data: NSData) throws -> [NSData: AnyObject] {
		return try self.decodeDictionary(NSDataByteStream(data: data))
	}

	class func decodeDictionary(byteStream: ByteStream) throws -> [NSData: AnyObject] {
		var result: [NSData: AnyObject] = [:]

		var currentByte = byteStream.nextByte()
		currentByte = byteStream.nextByte()

		while currentByte != ascii_e {
			byteStream.advanceBy(-1)

			let key = try self.decodeByteString(byteStream)
			let object = try self.decode(byteStream)

			result[key] = object

			currentByte = byteStream.nextByte()

		}

		return result
	}

	class func decodeStringKeyedDictionary(data: NSData) throws -> [String: AnyObject] {
		return try self.decodeStringKeyedDictionary(NSDataByteStream(data: data))
	}

	class func decodeStringKeyedDictionary(byteStream: ByteStream) throws -> [String: AnyObject] {
		var result: [String: AnyObject] = [:]

		var currentByte = byteStream.nextByte()
		currentByte = byteStream.nextByte()

		while currentByte != ascii_e {
			byteStream.advanceBy(-1)

			let key = try self.decodeString(byteStream)
			let object = try self.decode(byteStream, decodeDictionariesWithStringKeys: true)

			result[key] = object

			currentByte = byteStream.nextByte()
		}

		return result
	}

	class func decodeDictionaryKeysOnly(data: NSData) throws -> [String: NSData] {
		return try self.decodeDictionaryKeysOnly(NSDataByteStream(data: data))
	}

	class func decodeDictionaryKeysOnly(byteStream: ByteStream) throws -> [String: NSData] {
		var result = [String: NSData]()

		var currentByte = byteStream.nextByte()
		currentByte = byteStream.nextByte()

		while currentByte != ascii_e {
			byteStream.advanceBy(-1)

			let key = try self.decodeString(byteStream)

			let startIndex = byteStream.currentIndex
			let _ = try self.decode(byteStream)
			let numberOfBytesInValue = byteStream.currentIndex - startIndex
			byteStream.advanceBy(-numberOfBytesInValue)
			let value = byteStream.nextBytes(numberOfBytesInValue)

			result[key] = value

			currentByte = byteStream.nextByte()
		}

		return result
	}
}