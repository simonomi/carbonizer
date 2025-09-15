extension Carbonizer {
	struct InvalidInput: Error, CustomStringConvertible {
		var description: String {
			"invalid input type, must be either a .nds file or a carbonizer-unpacked ROM folder"
		}
	}
}
