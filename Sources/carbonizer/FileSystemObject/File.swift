import Foundation
import BinaryParser

func createFile(contentsOf path: URL) throws -> any FileSystemObject {
    let (name, fileExtension) = splitFileName(path.lastPathComponent)
	let data = Datastream(try Data(contentsOf: path))
	
	let metadata = try path
		.getCreationDate()
		.flatMap(Metadata.init)
	
	let file = try createFile(
		name: name,
		fileExtension: fileExtension,
		metadata: metadata,
		data: data
	)
	
	if metadata?.standalone == true {
		let fileName = switch file {
			case is ProprietaryFile: file.name
			default: file.fullName
		}
		
		return MAR(
			name: fileName,
			files: [try MCM(file)!] // a file with metadata should always be an MCM
		)
	} else {
		return file
	}
}

func createFile(
	name: String,
	fileExtension: String,
	metadata: Metadata?,
	data: Datastream
) throws -> any FileSystemObject {
	if fileExtension == PackedNDS.fileExtension {
		return PackedNDS(
			name: name,
			binary: try data.read(NDS.Binary.self)
		)
	}
	
	let marker = data.placeMarker()
	let magicBytes = (try? data.read(String.self, length: 3)) ?? ""
	data.jump(to: marker)
	
	                                       /*  makes ffc work right  */
	if magicBytes == MAR.Binary.magicBytes /*&& !name.contains("arc")*/ {
		return PackedMAR(
			name: name,
			fileExtension: fileExtension,
			binary: try data.read(MAR.Binary.self)
		)
	}
	
	if let fileData = try createFileData(data, fileExtension: fileExtension) {
		return ProprietaryFile(
			name: name,
			metadata: metadata,
			data: fileData
		)
	} else {
		return BinaryFile(
			name: name,
			fileExtension: fileExtension,
			metadata: metadata,
			data: data
		)
	}
}
