//
//  CompressionHeader.swift
//
//
//  Created by simon pellerin on 2023-06-20.
//

struct CompressionHeader {
	var dataSize: UInt8 // 4 bits, 0 unless huffman
	var type: CompressionType // 4 bits
	var decompressedSize: UInt32 // 24 bits
	
	enum CompressionType: UInt8 {
		case lzss = 1, huffman, runLength
	}
	
	enum InputError: Error {
		case invalidCompressionType(UInt8)
	}
	
	init(dataSize: UInt8 = 0, type: CompressionType, decompressedSize: UInt32) {
		self.dataSize = dataSize
		self.type = type
		self.decompressedSize = decompressedSize
	}
	
	init(from data: Datastream) throws {
		let headerData = try data.read(UInt32.self)
		
		dataSize = UInt8(headerData & 0b1111)
		
		let typeData = UInt8((headerData >> 4) & 0b1111)
		guard let compressionType = CompressionType(rawValue: typeData) else {
			throw InputError.invalidCompressionType(typeData)
		}
		
		type = compressionType
		decompressedSize = headerData >> 8
	}
	
	func write(to data: Datawriter) {
		let headerData = UInt32(dataSize) | UInt32(type.rawValue << 4) | (decompressedSize << 8)
		data.write(headerData)
	}
}
