import Foundation
import BinaryParser

func makeFile(
	contentsOf path: URL,
	configuration: Configuration
) throws -> (any FileSystemObject)? {
	let metadata = try Metadata(forItemAt: path)
	if metadata?.skipFile == true { return nil }
	
	configuration.log(.transient, "Reading", path.path(percentEncoded: false))
	
	let name = path.lastPathComponent
	let data = Datastream(try Data(contentsOf: path))
	
	let file = try makeFile(
		name: name,
		metadata: metadata,
		data: data,
		configuration: configuration
	)
	
	if metadata?.standalone == true {
		guard let mcm = try MCM.Unpacked(file) else {
			throw ExtraneousMetadataError(on: path)
		}
		
		return MAR.Unpacked(name: file.name, files: [mcm])
	} else {
		return file
	}
}

struct ExtraneousMetadataError: Error, CustomStringConvertible {
	var filePath: URL
	
	init(on path: URL) {
		filePath = path
	}
	
	var description: String {
		"the file '\(filePath)' has metadata, which it shouldnt. check if the creation date is correct"
	}
}

func makeFile(
	name: String,
	metadata: Metadata?,
	data: Datastream,
	configuration: Configuration
) throws -> any FileSystemObject {
	if name.hasSuffix(NDS.Packed.fileExtension) {
		return NDS.Packed(
			name: String(name.dropLast(NDS.Packed.fileExtension.count)),
			binary: try data.read(NDS.Packed.Binary.self)
		)
	}
	
	if configuration.fileTypes.contains("MAR") {
		let marker = data.placeMarker()
		let magicBytes = try? data.read(String.self, exactLength: 3)
		data.jump(to: marker)
		
		if magicBytes == MAR.Packed.Binary.magicBytes {
			return MAR.Packed(
				name: name,
				binary: try data.read(MAR.Packed.Binary.self)
			)
		}
	}
	
	let fileData = try makeFileData(
		name: name,
		data: data,
		configuration: configuration
	)
	
	if let fileData {
		let fileType = type(of: fileData)
		
		guard let isPacked = fileType.packedStatus.isPacked else {
			preconditionFailure("proprietary file type \(fileType) is neither packed or unpacked")
		}
		
		let newName = if isPacked {
			name
		} else {
			String(name.dropLast(fileType.fileExtension.count))
		}
		
		return ProprietaryFile(
			name: newName,
			metadata: metadata,
			data: fileData
		)
	} else {
		return BinaryFile(
			name: name,
			metadata: metadata,
			data: data
		)
	}
}
