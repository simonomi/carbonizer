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
		var indexes: [Index]
		@Offsets(givenBy: \Self.indexes, at: \.fileOffset)
		var files: [MCM.Binary]
		
		@BinaryConvertible
		struct Index {
			var fileOffset: UInt32
			var decompressedSize: UInt32
		}
	}
}


extension MAR: FileSystemObject {
	var fileExtension: String { "mar" }
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		Folder(name: name, contents: [])
			.savePath(in: directory, overwriting: overwriting)
	}
	
	func write(to path: URL) throws {
		if files.count == 1,
		   let file = files.first
		{
			try ProprietaryFile(name: name, standaloneMCM: file)
				.write(to: path)
		} else {
			try Folder(
				name: fullName,
				contents: files.enumerated().map(ProprietaryFile.init)
			).write(to: path)
		}
	}
	
	func packedStatus() -> PackedStatus { .unpacked }
	
	func packed() -> PackedMAR {
		let (name, fileExtension) = splitFileName(name)
		
		return PackedMAR(
			name: name,
			fileExtension: fileExtension,
			binary: MAR.Binary(self)
		)
	}
	
	func unpacked() throws -> Self { self }
}

struct PackedMAR: FileSystemObject {
	var name: String
	var fileExtension: String
	var binary: MAR.Binary
	
	func savePath(in directory: URL, overwriting: Bool) -> URL {
		BinaryFile(
			name: name,
			fileExtension: fileExtension,
			data: Datastream()
		)
		.savePath(in: directory, overwriting: overwriting)
	}
	
	func write(to path: URL) throws {
		let writer = Datawriter()
		writer.write(binary)
		
		try BinaryFile(
			name: name,
			fileExtension: fileExtension,
			data: writer.intoDatastream()
		)
		.write(to: path)
	}
	
	func packedStatus() -> PackedStatus { .packed }
	
	func packed() -> Self { self }
	
	func unpacked() throws -> MAR {
		try MAR(
			name: combineFileName(name, withExtension: fileExtension),
			binary: binary
		)
	}
}


// MARK: packed
extension MAR {
	static let fileExtension = "mar"
	
	init(name: String, binary: Binary) throws {
		logProgress("Decompressing", name)
		self.name = name
		
		do {
			files = try binary.files.map(MCM.init)
		} catch {
			throw BinaryParserError.whileReadingFile(name, "mar", "", error)
		}
	}
}

extension MAR.Binary {
	init(_ mar: MAR) {
		fileCount = UInt32(mar.files.count)
		
		files = mar.files.map(MCM.Binary.init)
		
		let firstFileIndex = 8 + fileCount * 8
		let mcmSizes = files.map(\.endOfFileOffset)
		let offsets = createOffsets(start: firstFileIndex, sizes: mcmSizes)
		
		let decompressedSizes = files.map(\.decompressedSize)
		
		indexes = zip(offsets, decompressedSizes).map(Index.init)
	}
}
