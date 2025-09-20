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
			(.runLength, "lorem ipsum - decompressed", "lorem ipsum - run length"),
			(.lzss, "lorem ipsum - decompressed", "lorem ipsum - lzss"),
//			(.huffman, "lorem ipsum - decompressed", "lorem ipsum - huffman"), // doesnt exist yet
//			(.huffman, "e0046 - lzss", "e0046 - huffman"), // 4-bit
			(.lzss, "e0046 - decompressed", "e0046 - lzss"),
//			(.huffman, "msg_0911 - decompressed", "msg_0911 - huffman"), // 8-bit
//			(.huffman, "msg_1007 - decompressed", "msg_1007 - huffman"), // 8-bit
//			(.huffman, "kaseki_defs - lzss", "kaseki_defs - huffman"), // ?-bit
			(.lzss, "kaseki_defs - decompressed", "kaseki_defs - lzss"),
		] as [(MCM.Unpacked.CompressionType, String, String)]
	)
	func compress(_ type: MCM.Unpacked.CompressionType, _ decompressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: decompressedFileName)
		
		let inputFilePath: URL = .compressionDirectory
			.appending(component: decompressedFileName)
			.appendingPathExtension("bin")
		
		let compressionInfo = try Metadata(forItemAt: inputFilePath)?.huffmanCompressionInfo.first
		
//		let start = Date.now

		// lzss is *notably* slower, ~0.3–3s compared to ~0.001–0.01s (in debug mode)
		// thats 300x!!
		let compressedInput = type.compress(inputData, compressionInfo: compressionInfo)
		
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
			(.runLength, "lorem ipsum - run length", "lorem ipsum - decompressed"),
			(.lzss, "lorem ipsum - lzss", "lorem ipsum - decompressed"),
//			(.huffman, "lorem ipsum - huffman", "lorem ipsum - decompressed"),
			(.huffman, "e0046 - huffman", "e0046 - lzss"),
			(.lzss, "e0046 - lzss", "e0046 - decompressed"),
			(.huffman, "msg_0911 - huffman", "msg_0911 - decompressed"),
			(.huffman, "msg_1007 - huffman", "msg_1007 - decompressed"),
			(.huffman, "kaseki_defs - huffman", "kaseki_defs - lzss"),
			(.lzss, "kaseki_defs - lzss", "kaseki_defs - decompressed"),
		] as [(MCM.Unpacked.CompressionType, String, String)]
	)
	func decompress(_ type: MCM.Unpacked.CompressionType, _ compressedFileName: String, _ expectedFileName: String) throws {
		let inputData = try data(for: compressedFileName)
		
//		let start = Date.now
		
		let (decompressedInput, _) = try type.decompress(inputData)
//		print(expectedFileName)
		
//		print("\(.yellow)decompress", type, start.timeElapsed, "\(.normal)")
		
		let expectedURL: URL = .compressionDirectory
			.appending(component: expectedFileName)
			.appendingPathExtension("bin")
		if !expectedURL.exists() {
			print("\(.green)saving decompression to '\(.cyan)\(expectedFileName).bin\(.green)'\(.normal)")
			try Data(decompressedInput.bytes).write(to: expectedURL)
			
//			let metadata = compressionInfo.map {
//				Metadata(skipFile: false, standalone: false, compression: (.huffman, .lzss), maxChunkSize: 4000, index: 0, huffmanCompressionInfo: [$0])
//			}
//			
//			if let metadata {
//				try JSONEncoder().encode(metadata).write(to: .temporaryDirectory.appending(component: expectedFileName + ".metadata"))
//				print(URL.temporaryDirectory.appending(component: expectedFileName + ".metadata").path(percentEncoded: false))
//			}
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
