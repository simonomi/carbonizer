extension UInt8 {
	// this isn't a very good solution, but the assertions only run in debug so who cares
	@usableFromInline
	var isFillerByte: Bool {
		self == 0 || self == 0xFF
	}
}
