import BinaryParser
import Foundation

struct MAR {
	var name: String
	var files: [MCM]
	
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "MAR"
		var fileCount: UInt32
		@Count(givenBy: \Self.fileCount)
		var indices: [Index]
		@Offsets(givenBy: \Self.indices, at: \.fileOffset)
		var files: [MCM.Binary]
		
		@BinaryConvertible
		struct Index {
			var fileOffset: UInt32
			var decompressedSize: UInt32
		}
	}
}


extension MAR: FileSystemObject {
	func savePath(in folder: URL, overwriting: Bool) -> URL {
		if files.count == 1 {
			ProprietaryFile(name: name, data: Datastream())
				.savePath(in: folder, overwriting: overwriting)
		} else {
			Folder(
				name: name + Self.fileExtension,
				contents: []
			).savePath(in: folder, overwriting: overwriting)
		}
	}
	
	func write(into folder: URL, overwriting: Bool) throws {
		if files.count == 1, let file = files.first {
			try ProprietaryFile(name: name, standaloneMCM: file)
				.write(into: folder, overwriting: overwriting)
		} else {
			try Folder(
				name: name + Self.fileExtension,
				contents: files.enumerated().map(ProprietaryFile.init)
			).write(into: folder, overwriting: overwriting)
		}
	}
	
	func packedStatus() -> PackedStatus { .unpacked }
	
	func packed(configuration: CarbonizerConfiguration) -> PackedMAR {
		PackedMAR(
			name: name,
			binary: MAR.Binary(self, configuration: configuration),
			configuration: configuration
		)
	}
	
	func unpacked(configuration: CarbonizerConfiguration) throws -> Self { self }
}

struct PackedMAR: FileSystemObject {
	var name: String
	var binary: MAR.Binary
	
	var configuration: CarbonizerConfiguration
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		BinaryFile(
			name: name,
			data: Datastream()
		)
		.savePath(in: directory, overwriting: overwriting)
	}
	
	func write(into path: URL, overwriting: Bool) throws {
		let writer = Datawriter()
		writer.write(binary)
		
		do {
			try BinaryFile(
				name: name,
				data: writer.intoDatastream()
			)
			.write(into: path, overwriting: overwriting)
		} catch {
			throw BinaryParserError.whileWriting(Self.self, error)
		}
	}
	
	func packedStatus() -> PackedStatus { .packed }
	
	func packed(configuration: CarbonizerConfiguration) -> Self { self }
	
	func unpacked(configuration: CarbonizerConfiguration) throws -> MAR {
		try MAR(
			name: name,
			binary: binary,
			configuration: configuration
		)
	}
}


// MARK: packed
extension MAR {
	static let fileExtension = ".mar"
	
	init(
		name: String,
		binary: Binary,
		configuration: CarbonizerConfiguration
	) throws {
		logProgress(
			"Decompressing", name,
			configuration: configuration
		)
		self.name = name
		
		do {
			files = try binary.files.map { try MCM($0, configuration: configuration) }
		} catch {
			throw BinaryParserError.whileReadingFile(name, error)
		}
	}
}

extension MAR.Binary {
	init(_ mar: MAR, configuration: CarbonizerConfiguration) {
		fileCount = UInt32(mar.files.count)
		
		files = mar.files.map { MCM.Binary($0, configuration: configuration) }
		
		let firstFileIndex = 8 + fileCount * 8
		let mcmSizes = files.map(\.endOfFileOffset)
		let offsets = makeOffsets(start: firstFileIndex, sizes: mcmSizes)
		
		let decompressedSizes = files.map(\.decompressedSize)
		
		indices = zip(offsets, decompressedSizes).map(Index.init)
	}
}
