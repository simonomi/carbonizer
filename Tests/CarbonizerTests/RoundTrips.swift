import Testing
import Foundation

@testable import Carbonizer

fileprivate let filePath = URL(filePath: "/Users/simonomi/ff1/output/Fossil Fighters")!

// things to round-trip
// - the root nds rom
// - individual files, packed and unpacked
// - mar folders, nds unpacked, and standalone mars (metadata!)

@Test(
	arguments: [
		("japanese", .packed)
	] as [(String, PackedStatus)]
)
func roundTrip(_ fileName: String, _ packedStatus: PackedStatus) throws {
	let inputFilePath = filePath(for: fileName)
	
	let originalData = try Data(contentsOf: inputFilePath)
	let file = try fileSystemObject(contentsOf: inputFilePath, configuration: .defaultConfiguration)
	
	let repackedFile: any FileSystemObject = switch packedStatus {
		case .packed:
			try file
				.unpacked(path: [], configuration: .defaultConfiguration)
				.packed(configuration: .defaultConfiguration)
		case .unpacked:
			try file
				.packed(configuration: .defaultConfiguration)
				.unpacked(path: [], configuration: .defaultConfiguration)
		case .unknown, .contradictory:
			try Issue.failure("packed status must be either packed or unpacked")
	}
	
	let savePath = repackedFile.savePath(in: .temporaryDirectory, overwriting: true)
	try repackedFile.write(into: .temporaryDirectory, overwriting: true)
	
	let savedData = try Data(contentsOf: savePath)
	
	// TODO: compare metadata and file name
	
	let dataIsTheSame = originalData == savedData
	#expect(dataIsTheSame)
}

fileprivate func filePath(for fileName: String) -> URL {
	.roundTripsDirectory
	.appending(component: fileName)
	.appendingPathExtension("bin")
}
