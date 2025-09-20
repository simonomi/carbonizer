import BinaryParser

// see https://web.archive.org/web/20090131141306/http://kiwi.ds.googlepages.com/sdat.html
enum SDAT {
	@BinaryConvertible
	struct Packed {
		static let magicBytes = Header.magicBytes
		
		var header: Header
		
		// make datastream?
//		@Count(givenBy: \Self.header.symbolBlockSize)
		@Offset(givenBy: \Self.header.symbolBlockOffset)
		var symbolBlock: SymbolBlock
		
		@BinaryConvertible
		struct Header {
			// these 16 bytes are common between file types (inc magic bytes)
			@Include
			@Length(4) // default is null-terminated
			static let magicBytes = "SDAT"
			var magic: UInt32 = 0x0100feff // can vary?
										   // feff means big endian
										   // 0100 means version 1.0
			var fileSize: UInt32
			var headerSize: UInt16 = 0x40
			var blockCount: UInt16
			
			var symbolBlockOffset: UInt32 = 0x40
			var symbolBlockSize: UInt32;
			
			var infoBlockOffset: UInt32;
			var infoBlockSize: UInt32;
			
			var fatOffset: UInt32;
			var fatSize: UInt32;
			
			var fileBlockOffset: UInt32;
			var fileBlockSize: UInt32;
			
			@Padding(bytes: 0x10)
			var reserved: ()
		}
		
		@BinaryConvertible
		struct SymbolBlock {
			@Include
			@Length(4)
			static let magicBytes = "SYMB"
			
			var size: UInt32
			
			var sequenceRecordOffset: UInt32
			var sequenceArchiveRecordOffset: UInt32
			var soundBankNameOffsetsOffset: UInt32
			var waveArchiveNameOffsetsOffset: UInt32
			var playerNameOffsetsOffset: UInt32
			var groupNameOffsetsOffset: UInt32
			var player2NameOffsetsOffset: UInt32
			var streamNameOffsetsOffset: UInt32
			
			@Padding(bytes: 0x18)
			var reserved: ()
			
			@Offset(givenBy: \Self.sequenceRecordOffset)
			var sequenceRecord: Record
			
			@Offset(givenBy: \Self.sequenceArchiveRecordOffset)
			var sequenceArchiveRecord: ArchiveRecord
			
			@Offsets(givenBy: \Self.sequenceRecord.offsets)
			var sequenceNames: [String]
			
			@Offsets(givenBy: \Self.sequenceArchiveRecord.offsets, at: \.nameOffset)
			var sequenceArchiveCategoryNames: [String]
			
			@Offsets(givenBy: \Self.sequenceArchiveRecord.offsets, at: \.subRecordOffset)
			var sequenceArchiveSubRecords: [Record]
			
			@Offsets(givenBy: \Self.sequenceArchiveSubRecords, at: \.offsets)
			var sequenceArchiveNames: [[String]]
			
			@BinaryConvertible
			struct Record {
				var count: UInt32
				@Count(givenBy: \Self.count)
				var offsets: [UInt32]
			}
			
			@BinaryConvertible
			struct ArchiveRecord {
				var count: UInt32
				@Count(givenBy: \Self.count)
				var offsets: [Offset]
				
				@BinaryConvertible
				struct Offset {
					var nameOffset: UInt32 // to string
					var subRecordOffset: UInt32 // to record of string(?)
				}
			}
			
			// rest
		}
	}
	
	struct Unpacked: Codable {}
}

// MARK: packed
extension SDAT.Packed: ProprietaryFileData {
	static let fileExtension = ""
	static let packedStatus: PackedStatus = .packed
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> SDAT.Unpacked {
		SDAT.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: SDAT.Unpacked, configuration: Configuration) {
		todo()
	}
}

// MARK: unpacked
extension SDAT.Unpacked: ProprietaryFileData {
	static let fileExtension = ".sdat.json"
	static let magicBytes = ""
	static let packedStatus: PackedStatus = .unpacked
	
	func packed(configuration: Configuration) -> SDAT.Packed {
		SDAT.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: SDAT.Packed, configuration: Configuration) {
		print(packed.symbolBlock.sequenceNames)
		print(packed.symbolBlock.sequenceArchiveCategoryNames)
		print(packed.symbolBlock.sequenceArchiveNames)
		
		todo()
	}
}

