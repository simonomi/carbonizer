import Testing
import Foundation

import BinaryParser
@testable import Carbonizer

@Suite
struct Compression {
	@Test(
		arguments: [
//			(.lzss, "first japanese chunk - decompressed", "first japanese chunk - lzss"),
//			(.huffman, "first japanese chunk - lzss", "first japanese chunk - huffman"),
			(.runLength, "map c 0004 - decompressed", "map c 0004 - run length"),
//			(.huffman, "map c 0004 - run length", "map c 0004 - huffman"),
		] as [(MCM.CompressionType, String, String)]
	)
	func compress(_ type: MCM.CompressionType, _ decompressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: decompressedFileName)
		
		let compressedInput = type.compress(inputData)
		
		let expectedOutput = try data(for: expectedFileName)
		
		let areTheSame = compressedInput.bytes == expectedOutput.bytes
		#expect(areTheSame)
		
		let url: URL = .compressionDirectory.appending(component: "incorrect compression.bin")
		try Data(compressedInput.bytes).write(to: url)
	}
	
	@Test(
		arguments: [
			(.huffman, "first japanese chunk - huffman", "first japanese chunk - lzss"),
			(.lzss, "first japanese chunk - lzss", "first japanese chunk - decompressed"),
			(.huffman, "map c 0004 - huffman", "map c 0004 - run length"),
			(.runLength, "map c 0004 - run length", "map c 0004 - decompressed"),
		] as [(MCM.CompressionType, String, String)]
	)
	func decompress(_ type: MCM.CompressionType, _ compressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: compressedFileName)
		
		let decompressedInput = try type.decompress(inputData)
		
//		let expectedURL: URL = .compressionDirectory
//			.appending(component: expectedFileName)
//			.appendingPathExtension("bin")
//		if !expectedURL.exists() {
//			try Data(decompressedInput.bytes).write(to: expectedURL)
//		}
		
		let expectedOutput = try data(for: expectedFileName)
		
		let areTheSame = decompressedInput.bytes == expectedOutput.bytes
		#expect(areTheSame)
	}
}

fileprivate func data(for fileName: String) throws -> Datastream {
	try Datastream(Data(
		contentsOf: .compressionDirectory
			.appending(component: fileName)
			.appendingPathExtension("bin")
	))
}
