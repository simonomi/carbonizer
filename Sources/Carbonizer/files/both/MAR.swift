import BinaryParser
import Foundation

enum MAR {
	struct Packed {
		var name: String
		var binary: Binary
		
		@BinaryConvertible
		struct Binary {
			@Include
			static let magicBytes = "MAR"
			var fileCount: UInt32
			@Count(givenBy: \Self.fileCount)
			var indices: [Index]
			@Offsets(givenBy: \Self.indices, at: \.fileOffset)
			var files: [MCM.Packed]
			
			@BinaryConvertible
			struct Index {
				var fileOffset: UInt32
				var decompressedSize: UInt32
			}
		}
	}
	
	struct Unpacked {
		var name: String
		var files: [MCM.Unpacked]
	}
}

// MARK: packed
extension MAR.Packed: FileSystemObject {
	func savePath(in directory: URL, with configuration: Carbonizer.Configuration) -> URL {
		BinaryFile(
			name: name,
			data: Datastream()
		)
		.savePath(in: directory, with: configuration)
	}
	
	func write(
		into path: URL,
		with configuration: Carbonizer.Configuration
	) throws {
		let writer = Datawriter()
		writer.write(binary)
		
		do {
			try BinaryFile(
				name: name,
				data: writer.intoDatastream()
			)
			.write(into: path, with: configuration)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
	}
	
	func packedStatus() -> PackedStatus { .packed }
	
	func packed(configuration: Carbonizer.Configuration) -> Self { self }
	
	func unpacked(path: [String] = [], configuration: Carbonizer.Configuration) throws -> MAR.Unpacked {
		try MAR.Unpacked(
			name: name,
			binary: binary,
			configuration: configuration
		)
	}
}

extension MAR.Packed.Binary {
	init(_ mar: MAR.Unpacked, configuration: Carbonizer.Configuration) {
		fileCount = UInt32(mar.files.count)
		
		files = mar.files.map { MCM.Packed($0, configuration: configuration) }
		
		let firstFileIndex = 8 + fileCount * 8
		let mcmSizes = files.map(\.endOfFileOffset)
		let offsets = makeOffsets(start: firstFileIndex, sizes: mcmSizes)
		
		let decompressedSizes = files.map(\.decompressedSize)
		
		indices = zip(offsets, decompressedSizes).map(Index.init)
	}
}

// MARK: unpacked
extension MAR.Unpacked: FileSystemObject {
	static let fileExtension = ".mar"
	
	func savePath(in folder: URL, with configuration: Carbonizer.Configuration) -> URL {
		if files.count == 1 {
			ProprietaryFile(name: name, data: Datastream())
				.savePath(in: folder, with: configuration)
		} else {
			Folder(
				name: name + Self.fileExtension,
				contents: []
			).savePath(in: folder, with: configuration)
		}
	}
	
	func write(
		into folder: URL,
		with configuration: Carbonizer.Configuration
	) throws {
		if files.count == 1, let file = files.first {
			try ProprietaryFile(name: name, standaloneMCM: file)
				.write(into: folder, with: configuration)
		} else {
			try Folder(
				name: name + Self.fileExtension,
				contents: files.enumerated().map(ProprietaryFile.init)
			).write(into: folder, with: configuration)
		}
	}
	
	func packedStatus() -> PackedStatus { .unpacked }
	
	func packed(configuration: Carbonizer.Configuration) -> MAR.Packed {
		MAR.Packed(
			name: name,
			binary: MAR.Packed.Binary(self, configuration: configuration)
		)
	}
	
	func unpacked(path: [String] = [], configuration: Carbonizer.Configuration) throws -> Self { self }
	
	init(
		name: String,
		binary: MAR.Packed.Binary,
		configuration: Carbonizer.Configuration
	) throws {
		configuration.log("Decompressing", name)
		self.name = name
		
		do {
			files = try binary.files.map { try MCM.Unpacked($0, configuration: configuration) }
		} catch {
			throw BinaryParserError.whileReadingFile(name, error)
		}
	}
}
