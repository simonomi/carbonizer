import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	func write(into directory: URL, packed: Bool) throws
}

enum FileReadError: Error {
	case invalidFileType(URL, FileAttributeType?)
}

func CreateFileSystemObject(contentsOf path: URL) throws -> any FileSystemObject {
	switch try path.type() {
		case .file:
			return try File(contentsOf: path)
		case .folder:
			let folder = try Folder(contentsOf: path)
			
			if folder.name.hasSuffix(".mar") {
				return File(
					name: String(folder.name.dropLast(4)),
					data: try MAR(unpacked: folder.files)
				)
			} else if folder.files.contains(where: { $0.name == "header" }) {
				return File(
					name: folder.name,
					data: try NDS(unpacked: folder.files)
				)
			} else {
				return folder
			}
		case .other(let otherType):
			throw FileReadError.invalidFileType(path, otherType)
	}
}

struct Folder: FileSystemObject {
	var name: String
	var files: [any FileSystemObject]
	
	init(name: String, files: [any FileSystemObject]) {
		self.name = name
		self.files = files
	}
	
	init(contentsOf folderPath: URL) throws {
		name = folderPath.lastPathComponent
		files = try folderPath.contents()
			.filter { !$0.lastPathComponent.starts(with: ".") }
			.compactMap(CreateFileSystemObject)
			.sorted(by: \.name)
	}
	
	func write(into directory: URL, packed: Bool) throws {
		let path = directory.appending(component: name)
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		try files.forEach { try $0.write(into: path, packed: packed) }
	}
}

// technically this isnt correct, but its mostly probably good enough
extension Folder: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(files.count)
	}
	
	static func == (lhs: Folder, rhs: Folder) -> Bool {
		lhs.name == rhs.name && lhs.files.count == rhs.files.count
	}
}

struct File: FileSystemObject {
	var name: String
	var metadata: Metadata?
	var data: any FileData
	
	struct Metadata {
		var standalone: Bool // 1 bit
		var compression: (MCM.CompressionType, MCM.CompressionType) // 2 bits, 2 bits
		var maxChunkSize: UInt32 // 4 bits, then multiplied by 4kB
		var index: UInt16 // 16 bits
		
		init(standalone: Bool, compression: (MCM.CompressionType, MCM.CompressionType), maxChunkSize: UInt32, index: UInt16) {
			self.standalone = standalone
			self.compression = compression
			self.maxChunkSize = maxChunkSize
			self.index = index
		}
		
		init?(_ date: Date) {
			let data = Int(date.timeIntervalSince1970)
			
			let twentyFiveBitLimit = 33554432
			guard data < twentyFiveBitLimit else { return nil }
			
			let standaloneBit = data & 1
			let compression1Bits = data >> 1 & 0b11
			let compression2Bits = data >> 3 & 0b11
			let maxChunkSizeBits = data >> 5 & 0b1111
			let indexBits = data >> 9
			
			standalone = standaloneBit > 0
			
			compression = (
				MCM.CompressionType(rawValue: UInt8(compression1Bits)) ?? .none,
				MCM.CompressionType(rawValue: UInt8(compression2Bits)) ?? .none
			)
			
			maxChunkSize = UInt32(maxChunkSizeBits) * 0x1000
			
			index = UInt16(indexBits)
		}
		
		var asDate: Date {
			let standaloneBit = standalone ? 1 : UInt32.zero
			let compression1Bits = UInt32(compression.0.rawValue)
			let compression2Bits = UInt32(compression.1.rawValue)
			let maxChunkSizeBits = maxChunkSize / 0x1000
			let indexBits = UInt32(index)
			
			let outputBits = standaloneBit | compression1Bits << 1 | compression2Bits << 3 | maxChunkSizeBits << 5 | indexBits << 9
			return Date(timeIntervalSince1970: TimeInterval(outputBits))
		}
		
		func swizzle(_ body: (inout Self) -> Void) -> Self {
			var mutableSelf = self
			body(&mutableSelf)
			return mutableSelf
		}
	}
	
	init(contentsOf filePath: URL) throws {
		let fileExtension: String
		(name, fileExtension) = split(fileName: filePath.lastPathComponent)
		
		metadata = try filePath
			.getCreationDate()
			.flatMap(Metadata.init)
		
		let leftoverFileExtension: String
		(data, leftoverFileExtension) = try createFileData(name: name, extension: fileExtension, data: Data(contentsOf: filePath))
		if !leftoverFileExtension.isEmpty {
			name += "." + leftoverFileExtension
		}
		
		if let metadata, metadata.standalone {
			data = MAR(files: [
				MCM(
					compression: metadata.compression,
					maxChunkSize: metadata.maxChunkSize,
					content: data
				)
			])
		}
	}
	
	init(named inputName: String, data inputData: Data) throws {
		let fileExtension: String
		(name, fileExtension) = split(fileName: inputName)
		
		let leftoverFileExtension: String
		(data, leftoverFileExtension) = try createFileData(name: name, extension: fileExtension, data: inputData)
		if !leftoverFileExtension.isEmpty {
			name += "." + leftoverFileExtension
		}
	}
	
	init(named inputName: String, data inputData: Datastream) throws {
		let fileExtension: String
		(name, fileExtension) = split(fileName: inputName)
		
		let leftoverFileExtension: String
		(data, leftoverFileExtension) = try createFileData(name: name, extension: fileExtension, data: inputData)
		if !leftoverFileExtension.isEmpty {
			name += "." + leftoverFileExtension
		}
	}
	
	init(name: String, metadata: Metadata? = nil, data: any FileData) {
		self.name = name
		self.metadata = metadata
		self.data = data
	}
	
	func write(into directory: URL, packed: Bool) throws {
		let fileExtension =
			if packed {
				type(of: data).packedFileExtension
			} else {
				type(of: data).unpackedFileExtension
			}
		
		let filePath = directory.appendingPathComponent(name).appendingPathExtension(fileExtension)
		
		if packed {
			try data.toPacked().write(to: filePath)
		} else {
			try data.toUnpacked().write(to: filePath)
		}
		
		if let metadata {
			try filePath.setCreationDate(to: metadata.asDate)
		}
	}
}

func split(fileName: String) -> (name: String, fileExtension: String) {
	let components = fileName.split(separator: ".")
	return (
		name: String(components.first!),
		fileExtension: components.dropFirst().joined(separator: ".")
	)
}

func createFileData(name: String, extension fileExtension: String, data: Data) throws -> (any FileData, leftoverFileExtension: String) {
	do {
		return try switch fileExtension {
//			case DAL.unpackedFileExtension: (DAL(unpacked: data), "")
			case DEX.unpackedFileExtension: (DEX(unpacked: data), "")
			case DMG.unpackedFileExtension: (DMG(unpacked: data), "")
			case DMS.unpackedFileExtension: (DMS(unpacked: data), "")
			case DTX.unpackedFileExtension: (DTX(unpacked: data), "")
			case MM3.unpackedFileExtension: (MM3(unpacked: data), "")
			case MPM.unpackedFileExtension: (MPM(unpacked: data), "")
			case RLS.unpackedFileExtension: (RLS(unpacked: data), "")
			case Data.unpackedFileExtension: (data, "")
			default: createFileData(name: name, extension: fileExtension, data: Datastream(data))
		}
	} catch {
		let magicBytes = String(bytes: data.prefix(3), encoding: .utf8) ?? ""
		throw BinaryParserError.whileReadingFile(name, fileExtension, magicBytes, error)
	}
}

func createFileData(name: String, extension fileExtension: String, data: Datastream) throws -> (any FileData, leftoverFileExtension: String) {
	let marker = data.placeMarker()
	let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
	data.jump(to: marker)
	
	do {
		return try switch fileExtension {
			case NDS.packedFileExtension: (NDS(packed: data), "")
			default:
				try switch magicBytes {
//					case "DAL": (DAL(packed: data), fileExtension)
					case "DEX": (DEX(packed: data), fileExtension)
					case "DMG": (DMG(packed: data), fileExtension)
					case "DMS": (DMS(packed: data), fileExtension)
					case "DTX": (DTX(packed: data), fileExtension)
					case "MAR": (MAR(packed: data), fileExtension)
					case "MM3": (MM3(packed: data), fileExtension)
					case "MPM": (MPM(packed: data), fileExtension)
					case "RLS": (RLS(packed: data), fileExtension)
					default: (data, fileExtension)
				}
		}
	} catch {
		throw BinaryParserError.whileReadingFile(name, fileExtension, magicBytes, error)
	}
}