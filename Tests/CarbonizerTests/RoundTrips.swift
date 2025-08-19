import Testing
import Foundation

@testable import Carbonizer

// things to round-trip
// - the root nds rom
// - individual files, packed and unpacked
// - mar folders, nds unpacked, and standalone mars (metadata!)
// - the repacked rom! this can be done without any compression

#if !IN_CI
@Suite
struct RoundTrips {
	@Test(
		arguments: [
			// without compression, these will always fail (they're MARs)
//			("japanese", .packed),
//			("map c 0004", .packed),
//			("map e 0048", .packed),
//			("map g 0047", .packed),
//			("e0046", .packed),
//			("episode 0002", .packed),
//			("msg_0911", .packed),
//			("msg_1007", .packed),
			("arcdin 3cl", .packed),
			("excavate_defs", .packed),
			("shop 0001", .packed),
			("shop 0002", .packed),
			("status_fiery", .packed),
			("creature_020", .packed),
			("chara 0001", .packed),
			("chara 0036", .packed),
			("battle 0001", .packed),
			("battle 0100", .packed),
			("battle 0117", .packed),
			("battle 0269", .packed),
			("battle 0587", .packed),
			("battle 0605", .packed),
		] as [(String, PackedStatus)]
	)
	func roundTrip(_ fileName: String, _ packedStatus: PackedStatus) throws {
		let inputFilePath = filePath(for: fileName)
		
		var configurationWithFileTypes: CarbonizerConfiguration = .defaultConfiguration
		configurationWithFileTypes.fileTypes.append("DBS")
		
		let file = try fileSystemObject(contentsOf: inputFilePath, configuration: configurationWithFileTypes)
		
		let repackedFile: any FileSystemObject = switch packedStatus {
			case .packed:
				try file
					.unpacked(path: [], configuration: configurationWithFileTypes)
					.packed(configuration: configurationWithFileTypes)
			case .unpacked:
				try file
					.packed(configuration: configurationWithFileTypes)
					.unpacked(path: [], configuration: configurationWithFileTypes)
			case .unknown, .contradictory:
				try Issue.failure("packed status must be either packed or unpacked")
		}
		
		let savePath = repackedFile.savePath(in: .temporaryDirectory, overwriting: true)
		try repackedFile.write(into: .temporaryDirectory, overwriting: true, with: configurationWithFileTypes)
		
		let originalData = try Data(contentsOf: inputFilePath)
		let savedData = try Data(contentsOf: savePath)
		
		// TODO: compare metadata and file name
		
		let dataIsTheSame = originalData == savedData
		#expect(dataIsTheSame, "nvim -d \"\(inputFilePath.path(percentEncoded: false))\" \"\(savePath.path(percentEncoded: false))\"")
	}
	
	@Test(.disabled())
	func roundTripROM() throws {
		guard let wholeROMPath = URL.wholeROMPath else { return }
		
		let wholeROM = try fileSystemObject(contentsOf: wholeROMPath, configuration: .defaultConfiguration)
		
		let unpackedROM = try wholeROM.unpacked(path: [], configuration: .defaultConfiguration)
		let unpackedSavePath = unpackedROM.savePath(in: .temporaryDirectory, overwriting: false)
		try unpackedROM.write(into: .temporaryDirectory, overwriting: false, with: .defaultConfiguration)
		
		let repackedROM = try fileSystemObject(contentsOf: unpackedSavePath, configuration: .defaultConfiguration)
			.packed(configuration: .defaultConfiguration)
		let repackedSavePath = repackedROM.savePath(in: .temporaryDirectory, overwriting: false)
		try repackedROM.write(into: .temporaryDirectory, overwriting: false, with: .defaultConfiguration)
		
		let reunpackedROM = try fileSystemObject(contentsOf: repackedSavePath, configuration: .defaultConfiguration)
			.unpacked(path: [], configuration: .defaultConfiguration)
		let reunpackedSavePath = reunpackedROM.savePath(in: .temporaryDirectory, overwriting: false)
		try reunpackedROM.write(into: .temporaryDirectory, overwriting: false, with: .defaultConfiguration)
		
		let rerepackedROM = try fileSystemObject(contentsOf: reunpackedSavePath, configuration: .defaultConfiguration)
			.packed(configuration: .defaultConfiguration)
		let rerepackedSavePath = rerepackedROM.savePath(in: .temporaryDirectory, overwriting: false)
		try rerepackedROM.write(into: .temporaryDirectory, overwriting: false, with: .defaultConfiguration)
		
		func expectContents(
			of firstPath: URL,
			areEqualTo secondPath: URL,
			sourceLocation: SourceLocation = #_sourceLocation
		) throws {
			if try firstPath.type() == .file {
				let firstContents = try Data(contentsOf: firstPath)
				let secondContents = try Data(contentsOf: secondPath)
				
				let areTheSame = firstContents == secondContents
				
				#expect(
					areTheSame,
					"files '\(firstPath.path(percentEncoded: false))' and '\(secondPath.path(percentEncoded: false))' differ",
					sourceLocation: sourceLocation
				)
			} else {
				let firstContents = try firstPath.contents()
				let secondContents = try secondPath.contents()
				
				#expect(
					firstContents.count == secondContents.count,
					"different number of files in '\(firstPath.path(percentEncoded: false))' and '\(secondPath.path(percentEncoded: false))'",
					sourceLocation: sourceLocation
				)
				
				for (firstPath, secondPath) in zip(firstContents, secondContents) {
					try expectContents(of: firstPath, areEqualTo: secondPath, sourceLocation: sourceLocation)
				}
			}
		}
		
		// enable once compression has been added
//		try expectContents(of: wholeROMPath, areEqualTo: repackedSavePath)
		try expectContents(of: unpackedSavePath, areEqualTo: reunpackedSavePath)
		try expectContents(of: repackedSavePath, areEqualTo: rerepackedSavePath)
	}
}

fileprivate func filePath(for fileName: String) -> URL {
	.roundTripsDirectory
	.appending(component: fileName)
	.appendingPathExtension("bin")
}
#endif
