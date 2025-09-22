import Testing
import Foundation

import ANSICodes
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
//			("japanese mar", .packed),
//			("map c 0004 mar", .packed),
//			("map e 0048 mar", .packed),
//			("map g 0047 mar", .packed),
//			("e0046 mar", .packed),
//			("episode 0002 mar", .packed),
//			("msg_0911 mar", .packed),
//			("msg_1007 mar", .packed),
			("japanese", .packed),
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
			("creature_offset_defs", .packed),
			("creature_defs", .packed),
			("kaseki_defs", .packed),
			("map e 0033", .packed),
			("map e 0067", .packed),
			("map m 0118", .packed),
			("map m 0033", .packed),
			("map m 0057", .packed),
			("map m 0121", .packed),
			("map_bgm_match", .packed),
			("talk_msg_match", .packed),
			("attack_defs", .packed),
			("battle_attack_type", .packed),
			("btl_kp_defs", .packed),
			("senryu_defs", .packed),
			("keyitem_defs", .packed),
			("image all_map", .packed),
			("headmask_defs", .packed),
			("msg_1007", .packed),
			("btl_bg_defs", .packed),
			("episode 0046", .packed),
			("episode 0002", .packed),
			("episode 0048", .packed),
			("episode 0088", .packed),
			("map r 0025", .packed),
			("museum_defs", .packed),
			("btl_tuto_001", .packed),
		] as [(String, PackedStatus)]
	)
	func roundTrip(_ fileName: String, _ packedStatus: PackedStatus) throws {
		let inputFilePath = filePath(for: fileName)
		
		let configurationWithFileTypes = try Configuration(
			overwriteOutput: true,
			dexCommandList: .ff1,
			externalMetadata: false,
			fileTypes: ["DBT"],
			onlyUnpack: [],
			skipUnpacking: [],
			processors: [],
			logHandler: nil
		)
		
		let file = try fileSystemObject(contentsOf: inputFilePath, configuration: configurationWithFileTypes)!
		
		let toggledFile: any FileSystemObject = switch packedStatus {
			case .packed:
				try file.unpacked(path: [], configuration: configurationWithFileTypes)
			case .unpacked:
				file.packed(configuration: configurationWithFileTypes)
			case .unknown, .contradictory:
				try Issue.failure("packed status must be either packed or unpacked")
		}
		
		let toggledSavePath = toggledFile.savePath(in: .temporaryDirectory, with: configurationWithFileTypes)
		try toggledFile.write(into: .temporaryDirectory, with: configurationWithFileTypes)
		
		let rereadFile = try fileSystemObject(contentsOf: toggledSavePath, configuration: configurationWithFileTypes)!
		
		let retoggledFile: any FileSystemObject = switch packedStatus {
			case .packed:
				rereadFile.packed(configuration: configurationWithFileTypes)
			case .unpacked:
				try rereadFile.unpacked(path: [], configuration: configurationWithFileTypes)
			case .unknown, .contradictory:
				try Issue.failure("packed status must be either packed or unpacked")
		}
		
		let savePath = retoggledFile.savePath(in: .temporaryDirectory, with: configurationWithFileTypes)
		try retoggledFile.write(into: .temporaryDirectory, with: configurationWithFileTypes)
		
		let originalData = try Data(contentsOf: inputFilePath)
		let savedData = try Data(contentsOf: savePath)
		
		// TODO: compare metadata and file name
		
		let dataIsTheSame = originalData == savedData
		#expect(dataIsTheSame, "nvim -d \"\(inputFilePath.path(percentEncoded: false))\" \"\(savePath.path(percentEncoded: false))\"")
	}
	
	@Test(.disabled())
	func roundTripROM() throws {
		guard let wholeROMPath = URL.wholeROMPath else { return }
		
		let configuration = try Configuration(
			overwriteOutput: true,
			dexCommandList: .ff1,
			externalMetadata: false,
			fileTypes: [],
			onlyUnpack: [],
			skipUnpacking: [],
			processors: [],
			logHandler: nil
		)
		
		let wholeROM = try fileSystemObject(contentsOf: wholeROMPath, configuration: configuration)!
		
		let unpackedROM = try wholeROM.unpacked(path: [], configuration: configuration)
		let unpackedSavePath = unpackedROM.savePath(in: .temporaryDirectory, with: configuration)
		try unpackedROM.write(into: .temporaryDirectory, with: configuration)
		
		let repackedROM = try fileSystemObject(contentsOf: unpackedSavePath, configuration: configuration)!
			.packed(configuration: configuration)
		let repackedSavePath = repackedROM.savePath(in: .temporaryDirectory, with: configuration)
		try repackedROM.write(into: .temporaryDirectory, with: configuration)
		
		let reunpackedROM = try fileSystemObject(contentsOf: repackedSavePath, configuration: configuration)!
			.unpacked(path: [], configuration: configuration)
		let reunpackedSavePath = reunpackedROM.savePath(in: .temporaryDirectory, with: configuration)
		try reunpackedROM.write(into: .temporaryDirectory, with: configuration)
		
		let rerepackedROM = try fileSystemObject(contentsOf: reunpackedSavePath, configuration: configuration)!
			.packed(configuration: configuration)
		let rerepackedSavePath = rerepackedROM.savePath(in: .temporaryDirectory, with: configuration)
		try rerepackedROM.write(into: .temporaryDirectory, with: configuration)
		
		func expectContents(
			of firstPath: URL,
			areEqualTo secondPath: URL,
			sourceLocation: SourceLocation = #_sourceLocation
		) throws {
			if try firstPath.isDirectory() {
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
			} else {
				let firstContents = try Data(contentsOf: firstPath)
				let secondContents = try Data(contentsOf: secondPath)
				
				let areTheSame = firstContents == secondContents
				
				#expect(
					areTheSame,
					"files '\(firstPath.path(percentEncoded: false))' and '\(secondPath.path(percentEncoded: false))' differ",
					sourceLocation: sourceLocation
				)
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
