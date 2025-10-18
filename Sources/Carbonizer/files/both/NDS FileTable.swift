extension NDS.Unpacked {
	struct FileTables: Codable {
		var allocations: [String: NDS.Packed.Binary.FileAllocationTableEntry]
		
		init(
			nameTable: CompleteFNT,
			allocationTable: [NDS.Packed.Binary.FileAllocationTableEntry]
		) {
			let fileIDs = nameTable.fileIDs()
			
			// TODO: doesn't contain overlays
			allocations = fileIDs.mapValues {
				allocationTable[Int($0)] // TODO: bounds checking
				// what to do if out of bounds?
				// uhh what does that mean again??
			}
		}
		
		func existingOffsets(
			for newNameTable: CompleteFNT
		) throws -> [UInt16: NDS.Packed.Binary.FileAllocationTableEntry] {
			let newFileIDs = newNameTable.fileIDs()
			
			// TODO: doesn't contain overlays
			
			// there shouldn't be duplicate fileIDs unless there are duplicate paths,
			// which are dictionary keys, so they should always be unique
			return Dictionary(
				uniqueKeysWithValues: allocations.compactMap { (path, entry) in
					newFileIDs[path].map { fileID in
						(fileID, entry)
					}
				}
			)
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
