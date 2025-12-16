import BinaryParser
import Foundation

enum MCM {
	@BinaryConvertible
	struct Packed {
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
	
	struct Unpacked {
		var compression: (CompressionType, CompressionType)
		var maxChunkSize: UInt32
		
		var huffmanCompressionInfo: [(Huffman.CompressionInfo?, Huffman.CompressionInfo?)]
		
		var content: any ProprietaryFileData
		
		enum CompressionType: UInt8 {
			case none, runLength, lzss, huffman
		}
	}
}

// MARK: packed
extension MCM.Packed {
	struct MissingCompressionInfo: Error, CustomStringConvertible {
		var chunkCount: Int
		var compressionInfoCount: Int
		
		var description: String {
			"compression info is missing (expected \(.green)\(chunkCount)\(.normal) chunk\(sIfPlural(chunkCount)), got \(.red)\(compressionInfoCount)\(.normal)), did you enable external metadata?"
		}
	}
	
	init(_ unpacked: MCM.Unpacked, configuration: Configuration) throws {
		maxChunkSize = unpacked.maxChunkSize
		
		if configuration.compression {
			compressionType1 = unpacked.compression.0.rawValue
			compressionType2 = unpacked.compression.1.rawValue
		} else {
			compressionType1 = 0
			compressionType2 = 0
		}
		
		let data = Datawriter()
		unpacked.content.packed(configuration: configuration).write(to: data)
		
		decompressedSize = UInt32(data.bytes.endIndex)
		
		let chunkedData = data
			.intoDatastream()
			.chunked(maxSize: Int(maxChunkSize))
		
		if configuration.compression {
			guard unpacked.huffmanCompressionInfo.count == chunkedData.count else {
				throw MissingCompressionInfo(
					chunkCount: chunkedData.count,
					compressionInfoCount: unpacked.huffmanCompressionInfo.count
				)
			}
			
			let firstCompressionLayer = try zip(chunkedData, unpacked.huffmanCompressionInfo.map(\.1))
				.map(unpacked.compression.1.compress)
			
			chunks = try zip(firstCompressionLayer, unpacked.huffmanCompressionInfo.map(\.0))
				.map(unpacked.compression.0.compress)
		} else {
			chunks = chunkedData
		}
		
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
extension MCM.Unpacked {
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
	
	init(_ packed: MCM.Packed, in marName: String, configuration: Configuration) throws {
		compression = (
			CompressionType(rawValue: packed.compressionType1) ?? .none,
			CompressionType(rawValue: packed.compressionType2) ?? .none
		)
		maxChunkSize = packed.maxChunkSize
		
		do {
			// TODO: this can be optimized by having each chunk's
			// decompression functions write to the same buffer
			let decompressedChunksAndInfo = try packed.chunks
				.map(compression.0.decompress)
				.map { [compression] in (try compression.1.decompress($0), $1) }
			
			huffmanCompressionInfo = decompressedChunksAndInfo
				.map { ($0.1, $0.0.1) }
			
			let data = decompressedChunksAndInfo
				.map(\.0.0)
				.joined()
			
			content = try makeFileData(
				name: marName,
				data: data,
				configuration: configuration
			)?.unpacked(configuration: configuration) ?? data
		} catch {
			throw DecompressionError(compression: compression, wrapped: error)
		}
	}
	
	enum NoMetadataError: Error {
		case noMetadata(String)
	}
	
	init?(_ file: any FileSystemObject) throws(NoMetadataError) {
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
	init(index: Int, mcm: MCM.Unpacked) {
		name = String(index).padded(toLength: 4, with: "0")
		metadata = Metadata(
			skipFile: false,
			standalone: false,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: UInt16(index),
			huffmanCompressionInfo: mcm.huffmanCompressionInfo
		)
		data = mcm.content
	}
	
	init(name: String, standaloneMCM mcm: MCM.Unpacked) {
		self.name = name
		metadata = Metadata(
			skipFile: false,
			standalone: true,
			compression: mcm.compression,
			maxChunkSize: mcm.maxChunkSize,
			index: 0,
			huffmanCompressionInfo: mcm.huffmanCompressionInfo
		)
		data = mcm.content
	}
}

extension MCM.Unpacked.CompressionType: Codable {
	func compress(_ data: Datastream, compressionInfo: Huffman.CompressionInfo?) throws -> Datastream {
		switch self {
			case .none:                         data
			case .runLength: RunLength.compress(data)
			case .lzss:           LZSS.compress(data)
			case .huffman: try Huffman.compress(data, info: compressionInfo)
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
