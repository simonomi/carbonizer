import Foundation
import BinaryParser

func createFile(
	contentsOf path: URL,
	configuration: CarbonizerConfiguration
) throws -> any FileSystemObject {
	let name = path.lastPathComponent
	let data = Datastream(try Data(contentsOf: path))
	
	let metadata = try path
		.getCreationDate()
		.flatMap(Metadata.init)
	
	let file = try createFile(
		name: name,
		metadata: metadata,
		data: data,
		configuration: configuration
	)
	
	if metadata?.standalone == true {
		guard let mcm = try MCM(file) else {
			throw ExtraneousMetadataError(on: path)
		}
		
		return MAR(
			name: file.name,
			files: [try MCM(file)!], // a file with metadata should always be an MCM
			configuration: configuration
		)
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

func createFile(
	name: String,
	metadata: Metadata?,
	data: Datastream,
	configuration: CarbonizerConfiguration
) throws -> any FileSystemObject {
	if configuration.fileTypes.contains("NDS"), name.hasSuffix(PackedNDS.fileExtension) {
		return PackedNDS(
			name: String(name.dropLast(PackedNDS.fileExtension.count)),
			binary: try data.read(NDS.Binary.self),
			configuration: configuration
		)
	}
	
	if configuration.fileTypes.contains("MAR") {
		let marker = data.placeMarker()
		let magicBytes = try? data.read(String.self, exactLength: 3)
		data.jump(to: marker)
		
											   /*  makes ffc work right  */
		if magicBytes == MAR.Binary.magicBytes /*&& !name.contains("arc")*/ {
			return PackedMAR(
				name: name,
				binary: try data.read(MAR.Binary.self),
				configuration: configuration
			)
		}
	}
	
	let fileData = try createFileData(
		name: name,
		data: data,
		configuration: configuration
	)
	
	if let fileData {
		let fileType = type(of: fileData)
		
		guard let isPacked = fileType.packedStatus.isPacked else {
			fatalError("proprietary file type \(fileType) is neither packed or unpacked")
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
