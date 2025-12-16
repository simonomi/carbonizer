import Testing
import Foundation

import BinaryParser
@testable import Carbonizer

#if !IN_CI
@Suite
struct Compression {
	@Test(
		arguments: [
			(.lzss, "first japanese chunk - decompressed", "first japanese chunk - lzss"),
//			(.huffman, "first japanese chunk - lzss", "first japanese chunk - huffman"), // 4-bit
			(.runLength, "map c 0004 - decompressed", "map c 0004 - run length"),
//			(.huffman, "map c 0004 - run length", "map c 0004 - huffman"), // 8-bit
			(.runLength, "map e 0048 - decompressed", "map e 0048 - run length"),
			(.runLength, "map g 0047 - decompressed", "map g 0047 - run length"),
//			(.huffman, "e0046 - lzss", "e0046 - huffman"), // 4-bit
			(.lzss, "e0046 - decompressed", "e0046 - lzss"),
//			(.huffman, "msg_0911 - decompressed", "msg_0911 - huffman"), // 8-bit
//			(.huffman, "msg_1007 - decompressed", "msg_1007 - huffman"), // 8-bit
//			(.huffman, "kaseki_defs - lzss", "kaseki_defs - huffman"), // ?-bit
			(.lzss, "kaseki_defs - decompressed", "kaseki_defs - lzss"),
			(.runLength, "image_archive 0050 - decompressed", "image_archive 0050 - run-length"),
//			(.huffman, "image_archive 0050 - run-length", "image_archive 0050 - huffman"),
			(.runLength, "map c 0118 - decompressed", "map c 0118 - run-length"),
//			(.huffman, "map c 0118 - run-length", "map c 0118 - huffman"),
		] as [(MCM.Unpacked.CompressionType, String, String)]
	)
	func compress(_ type: MCM.Unpacked.CompressionType, _ decompressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: decompressedFileName)
		
		let inputFilePath: URL = .compressionDirectory
			.appending(component: decompressedFileName)
			.appendingPathExtension("bin")
		
		let compressionInfo = try Metadata(forItemAt: inputFilePath)?.huffmanCompressionInfo.first?.0
		
//		let start = Date.now

		// lzss is *notably* slower, ~0.3–3s compared to ~0.001–0.01s (in debug mode)
		// thats 300x!!
		let compressedInput = try type.compress(inputData, compressionInfo: compressionInfo)
		
//		print("\(.yellow)compress", type, start.timeElapsed, "\(.normal)")
		
		let expectedURL: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		if !expectedURL.exists() {
			print("\(.green)saving compressed file to '\(.cyan)\(expectedFileName).bin\(.green)'\(.normal)")
			try Data(compressedInput.bytes).write(to: expectedURL)
		}
		
		let expectedOutput = try data(for: expectedFileName)
		
		let expectedFilePath: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		
		let incorrectFilePath: URL = .compressionDirectory
			.appending(component: "incorrect \(expectedFileName).bin")
		
		let areTheSame = compressedInput.bytes == expectedOutput.bytes
		#expect(areTheSame, "nvim -d \"\(expectedFilePath.path(percentEncoded: false))\" \"\(incorrectFilePath.path(percentEncoded: false))\"")
		
		if !areTheSame {
			try Data(compressedInput.bytes).write(to: incorrectFilePath)
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
			(.huffman, "e0046 - huffman", "e0046 - lzss"),
			(.lzss, "e0046 - lzss", "e0046 - decompressed"),
			(.huffman, "msg_0911 - huffman", "msg_0911 - decompressed"),
			(.huffman, "msg_1007 - huffman", "msg_1007 - decompressed"),
			(.huffman, "kaseki_defs - huffman", "kaseki_defs - lzss"),
			(.lzss, "kaseki_defs - lzss", "kaseki_defs - decompressed"),
			(.huffman, "image_archive 0050 - huffman", "image_archive 0050 - run-length"),
			(.runLength, "image_archive 0050 - run-length", "image_archive 0050 - decompressed"),
			(.huffman, "map c 0118 - huffman", "map c 0118 - run-length"),
			(.runLength, "map c 0118 - run-length", "map c 0118 - decompressed"),
		] as [(MCM.Unpacked.CompressionType, String, String)]
	)
	func decompress(_ type: MCM.Unpacked.CompressionType, _ compressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: compressedFileName)
		
//		let start = Date.now
		
		let (decompressedInput, compressionInfo) = try type.decompress(inputData)
//		print(expectedFileName)
		
//		print("\(.yellow)decompress", type, start.timeElapsed, "\(.normal)")
		
		let expectedURL: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		if !expectedURL.exists() {
			print("\(.green)saving decompression to '\(.cyan)\(expectedFileName).bin\(.green)'\(.normal)")
			try Data(decompressedInput.bytes).write(to: expectedURL)
			
			if let compressionInfo {
				let metadata = Metadata(
					skipFile: false,
					standalone: false,
					compression: (.huffman, .lzss),
					maxChunkSize: 4000,
					index: 0,
					huffmanCompressionInfo: [(compressionInfo, nil)]
				)
				
				let compressionInfoPath: URL = .compressionDirectory
					.appending(component: expectedFileName)
					.appendingPathExtension("bin")
					.appendingPathExtension("metadata")
				
				try JSONEncoder().encode(metadata)
					.write(to: compressionInfoPath)
				
				print("\(.green)saving compression info to '\(.cyan)\(compressionInfoPath.lastPathComponent)\(.green)'\(.normal)")
			}
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
#endif
