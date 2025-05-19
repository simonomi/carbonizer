import BinaryParser
import Foundation

struct MCM {
	var compression: (CompressionType, CompressionType)
	var maxChunkSize: UInt32
	
	var huffmanCompressionInfo: [Huffman.CompressionInfo]
	
	var content: any ProprietaryFileData
	
	enum CompressionType: UInt8 {
		case none, runLength, lzss, huffman
		
		func compress(_ data: Datastream, compressionInfo: Huffman.CompressionInfo?) -> Datastream {
			switch self {
				case .none:                         data
				case .runLength: RunLength.compress(data)
				case .lzss:           LZSS.compress(data)
				case .huffman:     Huffman.compress(data, info: compressionInfo)
			}
		}
		
		func decompress(_ data: Datastream) throws -> (Datastream, Huffman.CompressionInfo?) {
			switch self {
				case .none:                               (data,  nil)
				case .runLength: (try RunLength.decompress(data), nil)
				case .lzss:           (try LZSS.decompress(data), nil)
				case .huffman:      try Huffman.decompress(data)
			}
		}
	}
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "MCM"
		var decompressedSize: UInt32
		var maxChunkSize: UInt32
		var chunkCount: UInt32
		var compressionType1: UInt8
		var compressionType2: UInt8
		@Padding(bytes: 2)
		@Count(givenBy: \Self.chunkCount)
		var chunkOffsets: [UInt32]
		var endOfFileOffset: UInt32
		@Offsets(givenBy: \Self.chunkOffsets)
		@EndOffset(givenBy: \Self.endOfFileOffset)
		var chunks: [Datastream]
	}
}

// MARK: packed
extension MCM {
	struct DecompressionError: WrappingError, CustomStringConvertible {
		var compression: (CompressionType, CompressionType)
		var wrapped: any Error
		
		var joinedErrorPrefix: String { ">" }
		
		var description: String {
			switch wrapped {
				case let error as WrappingError:
					"\(.bold)MCM\(.normal)\(error.joinedErrorPrefix)\(error)"
				case let error:
					"\(.bold)MCM\(.normal): \(error)"
			}
		}
	}
	
	init(_ binary: Binary, configuration: CarbonizerConfiguration) throws {
		compression = (
			CompressionType(rawValue: binary.compressionType1) ?? .none,
			CompressionType(rawValue: binary.compressionType2) ?? .none
		)
		maxChunkSize = binary.maxChunkSize
		
		do {
			// TODO: this can be optimized by having each chunk's
			// decompression functions write to the same buffer
			let decompressedChunksAndInfo = try binary.chunks
				.map(compression.0.decompress)
				.map { [compression] in (try compression.1.decompress($0), $1) }
			
			huffmanCompressionInfo = decompressedChunksAndInfo
				.flatMap { [$0.1, $0.0.1] }
				.compactMap { $0 }
			
			let data = decompressedChunksAndInfo
				.map(\.0.0)
				.joined()
			
#if compiler(>=6)
			content = try createFileData(
				name: "",
				data: data,
				configuration: configuration
			)?.unpacked(configuration: configuration) ?? data
#else
			let fileData = try createFileData(
				name: "",
				data: data,
				configuration: configuration
			)
			
			if let fileData {
				content = fileData.unpacked() as any ProprietaryFileData
			} else {
				content = data
			}
#endif
		} catch {
			throw DecompressionError(compression: compression, wrapped: error)
		}
	}
}

extension MCM.Binary {
	init(_ mcm: MCM, configuration: CarbonizerConfiguration) {
		maxChunkSize = mcm.maxChunkSize
		// TODO: turn back on once compression is implemented
//		compressionType1 = mcm.compression.0.rawValue
//		compressionType2 = mcm.compression.1.rawValue
		compressionType1 = 0
		compressionType2 = 0
		
		let data = Datawriter()
#if compiler(>=6)
		mcm.content.packed(configuration: configuration).write(to: data)
#else
		let packedContent: any ProprietaryFileData = mcm.content.packed()
		packedContent.write(to: data)
#endif
		
		decompressedSize = UInt32(data.offset)
		
		let chunkedData = data
			.intoDatastream()
			.chunked(maxSize: Int(maxChunkSize))
		
		chunks = chunkedData
//		let firstCompressionLayer = zip(chunkedData, mcm.huffmanCompressionInfo)
//			.map(mcm.compression.1.compress)
//		
//		chunks = zip(firstCompressionLayer, mcm.huffmanCompressionInfo)
//			.map(mcm.compression.0.compress)
		
		chunkCount = UInt32(chunks.count)
		
		chunkOffsets = makeOffsets(
			start: 24 + chunkCount * 4,
			sizes: chunks.map(\.bytes.count).map(UInt32.init)
		)
		
		if let lastChunkOffset = chunkOffsets.last,
		   let lastChunkSize = (chunks.last?.bytes.count).map(UInt32.init) {
			endOfFileOffset = lastChunkOffset + lastChunkSize
		} else {
			endOfFileOffset = 24
		}
	}
}

// MARK: unpacked
extension MCM {
	enum NoMetadataError: Error {
		case noMetadata(String)
	}
	
	init?(_ file: any FileSystemObject) throws {
		let metadata: Metadata?
		switch file {
			case let proprietaryFile as ProprietaryFile:
				content = proprietaryFile.data
				metadata = proprietaryFile.metadata
			case let binaryFile as BinaryFile:
				content = binaryFile.data
				metadata = binaryFile.metadata
			default:
				return nil
		}
		
		guard let metadata else {
			throw NoMetadataError.noMetadata(file.name)
		}
		
		compression = metadata.compression
		maxChunkSize = metadata.maxChunkSize
		huffmanCompressionInfo = metadata.huffmanCompressionInfo
	}
}

extension ProprietaryFile {
	init(index: Int, mcm: MCM) {
		name = String(index).padded(toLength: 4, with: "0")
		metadata = Metadata(
			standalone: false,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: UInt16(index),
			huffmanCompressionInfo: mcm.huffmanCompressionInfo
		)
		data = mcm.content
	}
	
	init(name: String, standaloneMCM mcm: MCM) {
		self.name = name
		metadata = Metadata(
			standalone: true,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: 0,
			huffmanCompressionInfo: mcm.huffmanCompressionInfo
		)
		data = mcm.content
	}
}

extension MCM.CompressionType: Codable {
	struct InvalidCompressionType: Error, CustomStringConvertible {
		var rawString: String
		
		init(_ rawString: String) {
			self.rawString = rawString
		}
		
		var description: String {
			"invalid compression type: '\(rawString)', expected one of 'none', 'run-length', 'lzss', or 'huffman'"
		}
	}
	
	init(from decoder: any Decoder) throws {
		let rawString = try decoder.singleValueContainer().decode(String.self)
		
		self = switch rawString {
			case "none": .none
			case "run-length": .runLength
			case "lzss": .lzss
			case "huffman": .huffman
			default: throw InvalidCompressionType(rawString)
		}
	}
	
	private var encodingString: String {
		switch self {
			case .none: "none"
			case .runLength: "run-length"
			case .lzss: "lzss"
			case .huffman: "huffman"
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(encodingString)
	}
}
