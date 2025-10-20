extension NDS.Unpacked {
	struct FileTables: Codable {
		typealias Entry = NDS.Packed.Binary.FileAllocationTableEntry
		
		var allocations: [String: Entry]
		var arm7Overlays: [UInt16: Entry]
		var arm9Overlays: [UInt16: Entry]
		
		init(
			nameTable: CompleteFNT,
			allocationTable: [Entry],
			arm7OverlayTable: [NDS.Packed.Binary.OverlayTableEntry],
			arm9OverlayTable: [NDS.Packed.Binary.OverlayTableEntry]
		) {
			let fileIDs = nameTable.fileIDs()
			
			allocations = fileIDs.mapValues {
				allocationTable[Int($0)] // TODO: bounds checking
				// what to do if out of bounds?
				// uhh what does that mean again??
			}
			
			arm7Overlays = Dictionary(
				uniqueKeysWithValues: arm7OverlayTable.map {
					(UInt16($0.fileId), allocationTable[Int($0.fileId)])
				}
			)
			
			arm9Overlays = Dictionary(
				uniqueKeysWithValues: arm9OverlayTable.map {
					(UInt16($0.fileId), allocationTable[Int($0.fileId)])
				}
			)
		}
		
		func existingOffsets(
			for newNameTable: CompleteFNT
		) throws -> [UInt16: Entry] {
			let newFileIDs = newNameTable.fileIDs()
			
			// there shouldn't be duplicate fileIDs unless there are duplicate paths,
			// which are dictionary keys, so they should always be unique
			return Dictionary(
				uniqueKeysWithValues: allocations.compactMap { (path, entry) in
					newFileIDs[path].map { fileID in
						(fileID, entry)
					}
				}
			)
			.merging(arm7Overlays) { _, _ in todo("duplicate file id with arm7 overlays") }
			.merging(arm9Overlays) { _, _ in todo("duplicate file id with arm9 overlays") }
		}
	}
}

extension CompleteFNT {
	func fileIDs() -> [String: UInt16] {
		// paths should be unique for each id, and each id should be unique
		[String: UInt16](
			uniqueKeysWithValues: self.flatMap { folderID, contents in
				contents
					.filter(\.isFile)
					.map { (path(for: folderID) + "/" + $0.name, $0.id!) }
			}
		)
	}
	
	func path(for folderID: UInt16) -> String {
		if folderID == 0xF000 {
			return ""
		}
		
		let parent = first {
			$0.value.contains {
				$0.id == folderID
			}
		}
		
		guard let parent else {
			todo("invalid fnt")
		}
		
		let parentID = parent.key
		
		// we checked above that parent contains us
		let name = parent.value.first {
			$0.id == folderID
		}!.name
		
		return path(for: parentID) + "/" + name
	}
}
