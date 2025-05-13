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
			(.runLength, "map e 0048 - decompressed", "map e 0048 - run length"),
			(.runLength, "map g 0047 - decompressed", "map g 0047 - run length"),
			(.runLength, "lorem ipsum - decompressed", "lorem ipsum - run length"),
//			(.lzss, "lorem ipsum - decompressed", "lorem ipsum - lzss"),
//			(.huffman, "lorem ipsum - decompressed", "lorem ipsum - huffman"),
		] as [(MCM.CompressionType, String, String)]
	)
	func compress(_ type: MCM.CompressionType, _ decompressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: decompressedFileName)
		
		let compressedInput = type.compress(inputData)
		
		let expectedURL: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		if !expectedURL.exists() {
			print("\(.green)saving compressed file to '\(.cyan)\(expectedFileName).bin\(.green)'\(.normal)")
			try Data(compressedInput.bytes).write(to: expectedURL)
		}
		
		let expectedOutput = try data(for: expectedFileName)
		
		let areTheSame = compressedInput.bytes == expectedOutput.bytes
		#expect(areTheSame)
		
		if !areTheSame {
			let url: URL = .compressionDirectory.appending(component: "incorrect \(expectedFileName).bin")
			try Data(compressedInput.bytes).write(to: url)
		}
	}
	
	@Test(
		arguments: [
			(.huffman, "first japanese chunk - huffman", "first japanese chunk - lzss"),
			(.lzss, "first japanese chunk - lzss", "first japanese chunk - decompressed"),
			(.huffman, "map c 0004 - huffman", "map c 0004 - run length"),
			(.runLength, "map c 0004 - run length", "map c 0004 - decompressed"),
			(.runLength, "map e 0048 - run length", "map e 0048 - decompressed"),
			(.runLength, "map g 0047 - run length", "map g 0047 - decompressed"),
			(.runLength, "lorem ipsum - run length", "lorem ipsum - decompressed"),
//			(.lzss, "lorem ipsum - lzss", "lorem ipsum - decompressed"),
//			(.huffman, "lorem ipsum - huffman", "lorem ipsum - decompressed"),
		] as [(MCM.CompressionType, String, String)]
	)
	func decompress(_ type: MCM.CompressionType, _ compressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: compressedFileName)
		
		let decompressedInput = try type.decompress(inputData)
		
		let expectedURL: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		if !expectedURL.exists() {
			print("\(.green)saving decompression to '\(.cyan)\(expectedFileName).bin\(.green)'\(.normal)")
			try Data(decompressedInput.bytes).write(to: expectedURL)
		}
		
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
