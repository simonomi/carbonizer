import BinaryParser

struct DMS {
	var value: UInt32
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "DMS"
		var value: UInt32
	}
}

// MARK: packed
extension DMS: FileData {
    static let fileExtension = "dms.json"
    
    init(_ binary: Binary) {
        value = binary.value
    }
}

extension DMS.Binary: FileData {
    static let fileExtension = ""
    
    init(_ dms: DMS) {
        value = dms.value
    }
}

// MARK: unpacked
extension DMS: Codable {
	init(from decoder: Decoder) throws {
		value = try UInt32(from: decoder)
	}
	
	func encode(to encoder: Encoder) throws {
		try value.encode(to: encoder)
	}
}
