import BinaryParser

struct GRD {
	@BinaryConvertible
	struct Binary {
		@Include
		static let magicBytes = "GRD"
		
		var width: UInt32
		var height: UInt32
		
		var numberOfBytes: UInt32
		var offset: UInt32
		
		@Offset(givenBy: \Self.offset)
		@Length(givenBy: \Self.numberOfBytes)
		var gridData: Datastream
	}
}
