//
//  FileSystemObject.swift
//  
//
//  Created by alice on 2023-11-26.
//

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
					data: MAR(unpacked: folder.files)
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
			.sorted(by: \.lastPathComponent)
			.filter { !$0.lastPathComponent.starts(with: ".") }
			.compactMap(CreateFileSystemObject)
	}
	
	func write(into directory: URL, packed: Bool) throws {
		let path = directory.appending(component: name)
		try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
		try files.forEach { try $0.write(into: path, packed: packed) }
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
		
		data = try createFileData(name: name, extension: fileExtension, data: Data(contentsOf: filePath))
	}
	
	init(named inputName: String, data inputData: Data) throws {
		let fileExtension: String
		(name, fileExtension) = split(fileName: inputName)
		data = try createFileData(name: name, extension: fileExtension, data: inputData)
	}
	
	init(named inputName: String, data inputData: Datastream) throws {
		let fileExtension: String
		(name, fileExtension) = split(fileName: inputName)
		data = try createFileData(name: name, extension: fileExtension, data: inputData)
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

func createFileData(name: String, extension fileExtension: String, data: Data) throws -> any FileData {
	do {
		return try switch fileExtension {
			case "dex.json": DEX(unpacked: data)
			case "dmg.json": DMG(unpacked: data)
			case "dms.json": DMS(unpacked: data)
			case "dtx.json": DTX(unpacked: data)
			case "mm3.json": MM3(unpacked: data)
			case "mpm.json": MPM(unpacked: data)
			case "rls.json": RLS(unpacked: data)
			case     "json": data
			default: createFileData(name: name, extension: fileExtension, data: Datastream(data))
		}
	} catch {
		let magicBytes = String(bytes: data.prefix(3), encoding: .utf8) ?? ""
		throw BinaryParserError.whileReadingFile(name, fileExtension, magicBytes, error)
	}
}

func createFileData(name: String, extension fileExtension: String, data: Datastream) throws -> any FileData {
	let marker = data.placeMarker()
	let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
	data.jump(to: marker)
	
	do {
		return try switch fileExtension {
			case "nds": NDS(packed: data)
			default:
				try switch magicBytes {
					case "DEX": DEX(packed: data)
					case "DMG": DMG(packed: data)
					case "DMS": DMS(packed: data)
					case "DTX": DTX(packed: data)
					case "MAR": MAR(packed: data)
					case "MM3": MM3(packed: data)
					case "MPM": MPM(packed: data)
					case "RLS": RLS(packed: data)
					default:    data
				}
		}
	} catch {
		throw BinaryParserError.whileReadingFile(name, fileExtension, magicBytes, error)
	}
}
