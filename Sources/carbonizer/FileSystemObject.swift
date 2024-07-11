import BinaryParser
import Foundation

protocol FileSystemObject {
	var name: String { get }
	func write(into directory: URL, packed: Bool) throws
	
	consuming func postProcessed(with postProcessor: PostProcessor) rethrows -> Self
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
				inputPackedStatus.set(to: .unpacked)
				return File(
					name: String(folder.name.dropLast(4)),
					data: try MAR(unpacked: folder.files)
				)
			} else if folder.files.contains(where: { $0.name == "header" }) {
				inputPackedStatus.set(to: .unpacked)
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
		if try folderPath.contents().contains(where: { $0.lastPathComponent == "header.json" }) {
			// unfortunately, this can't go in CreateFileSystemObject
			// because it wouldn't be run until too late
			extractMARs.replaceAuto(with: .never)
		}
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
		
		let filePathWithoutExtension = directory.appendingPathComponent(name)
		let filePath = filePathWithoutExtension.appendingPathExtension(fileExtension)
		
		do {
			if packed {
				try data.toPacked().write(to: filePath)
			} else {
				try data.toUnpacked().write(to: filePath)
			}
		} catch {
			throw BinaryParserError.whileWriting(type(of: data), error)
		}
		
		do {
			if let metadata {
				// if we are writing a MAR as an unpacked file, it's a standalone,
				// and thus doesn't have its own file. metadata is handled
				// by the child's call to `write`
				if !(fileExtension == "mar" && !packed) {
					try filePath.setCreationDate(to: metadata.asDate)
				}
			}
		} catch {
			throw BinaryParserError.whileWriting(Metadata.self, error)
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
		switch fileExtension {
//			case DAL.unpackedFileExtension: 
//				inputPackedStatus.set(to: .unpacked)
//				return (try DAL(unpacked: data), "")
//			case DEX.unpackedFileExtension:
//				inputPackedStatus.set(to: .unpacked)
//				return (try DEX(unpacked: data), "") // TODO: slow! (~11s)
//			case DCL.unpackedFileExtension:
//				inputPackedStatus.set(to: .unpacked)
//				return (try DCL(unpacked: data), "")
			case DMG.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try DMG(unpacked: data), "")
			case DMS.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try DMS(unpacked: data), "")
			case DTX.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try DTX(unpacked: data), "")
			case MM3.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try MM3(unpacked: data), "")
			case MPM.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try MPM(unpacked: data), "")
			case RLS.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (try RLS(unpacked: data), "")
			case MMS.unpackedFileExtension, "bin.mms.json": // TODO: broken bad workaround
				inputPackedStatus.set(to: .unpacked)
				return (try MMS(unpacked: data), "")
//			case MFS.unpackedFileExtension:
//				inputPackedStatus.set(to: .unpacked)
//				return (try MFS(unpacked: data), "")
			case Data.unpackedFileExtension:
				inputPackedStatus.set(to: .unpacked)
				return (data, "")
			default:
				return try createFileData(name: name, extension: fileExtension, data: Datastream(data))
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
	
	// TODO: refactor, possibly into one function
	// at least lift NDS up, right??
	do {
		switch fileExtension {
			case NDS.packedFileExtension:
				inputPackedStatus.set(to: .packed)
				extractMARs.replaceAuto(with: .never)
				return (try NDS(packed: data), "")
			default:
				switch magicBytes {
//					case "DAL":
//						inputPackedStatus.set(to: .packed)
//						return (try DAL(packed: data), fileExtension)
//					case "DCL":
//						inputPackedStatus.set(to: .packed)
//						return (try DCL(packed: data), fileExtension)
					case "DEX":
						inputPackedStatus.set(to: .packed)
						return (try DEX(packed: data), fileExtension)
					case "DMG":
						inputPackedStatus.set(to: .packed)
						return (try DMG(packed: data), fileExtension)
					case "DMS":
						inputPackedStatus.set(to: .packed)
						return (try DMS(packed: data), fileExtension)
					case "DTX":
						inputPackedStatus.set(to: .packed)
						return (try DTX(packed: data), fileExtension)
					case "MAR":
						if extractMARs.shouldExtract {
							// ignores contradictions because of fast mode
							inputPackedStatus.set(to: .packed, ignoreContradiction: true)
							return (try MAR(packed: data), fileExtension)
						} else {
							return (data, fileExtension)
						}
					case "MM3":
						inputPackedStatus.set(to: .packed)
						return (try MM3(packed: data), fileExtension)
					case "MPM":
						inputPackedStatus.set(to: .packed)
						return (try MPM(packed: data), fileExtension)
					case "RLS":
						inputPackedStatus.set(to: .packed)
						return (try RLS(packed: data), fileExtension)
					case "MMS":
						inputPackedStatus.set(to: .packed)
						return (try MMS(packed: data), fileExtension)
//					case "MFS":
//						print(name, terminator: "\t")
//						inputPackedStatus.set(to: .packed)
//						return (try MFS(packed: data), fileExtension)
					default:
						return (data, fileExtension)
				}
		}
	} catch {
		throw BinaryParserError.whileReadingFile(name, fileExtension, magicBytes, error)
	}
}
