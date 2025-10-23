import BinaryParser

// ff1-only
enum BCO {
	@BinaryConvertible
	struct Packed {
		@Include
		static let magicBytes = "BCO"
		
		var count: UInt32
		var offset: UInt32 = 0xC
		
		@Count(givenBy: \Self.count)
		@Offset(givenBy: \Self.offset)
		var elements: [Element]
		
		@BinaryConvertible
		struct Element {
			var unknown1: UInt32
			var unknown2: UInt32
		}
	}
	
	struct Unpacked: Codable {
		var elements: [Element?]
		
		struct Element: Codable {
			var unknown1: UInt32
			var unknown2: UInt32
		}
	}
}

// MARK: packed
extension BCO.Packed: ProprietaryFileData {
	static let fileExtension = ""
	
	func packed(configuration: Configuration) -> Self { self }
	
	func unpacked(configuration: Configuration) -> BCO.Unpacked {
		BCO.Unpacked(self, configuration: configuration)
	}
	
	fileprivate init(_ unpacked: BCO.Unpacked, configuration: Configuration) {
		count = UInt32(unpacked.elements.count)
		
		elements = unpacked.elements.map(Element.init)
	}
}

extension BCO.Packed.Element {
	fileprivate init(_ unpacked: BCO.Unpacked.Element?) {
		if let unpacked {
			unknown1 = unpacked.unknown1
			unknown2 = unpacked.unknown2
		} else {
			unknown1 = 0
			unknown2 = 0
		}
	}
}

// MARK: unpacked
extension BCO.Unpacked: ProprietaryFileData {
	static let fileExtension = ".bco.json"
	static let magicBytes = ""
	
	func packed(configuration: Configuration) -> BCO.Packed {
		BCO.Packed(self, configuration: configuration)
	}
	
	func unpacked(configuration: Configuration) -> Self { self }
	
	fileprivate init(_ packed: BCO.Packed, configuration: Configuration) {
		elements = packed.elements.map(Element?.init)
	}
}

extension BCO.Unpacked.Element? {
	fileprivate init(_ packed: BCO.Packed.Element) {
		self = if packed.unknown1 == 0, packed.unknown2 == 0 {
			nil
		} else {
			BCO.Unpacked.Element(packed)
		}
	}
}

extension BCO.Unpacked.Element {
	fileprivate init(_ packed: BCO.Packed.Element) {
		unknown1 = packed.unknown1
		unknown2 = packed.unknown2
	}
}
