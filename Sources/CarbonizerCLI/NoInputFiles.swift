import ANSICodes

struct NoInputFiles: Error, CustomStringConvertible {
#if os(Windows)
	fileprivate let windowsSuggestion = ", try dragging the ROM (.nds file) onto this exe"
#else
	fileprivate let windowsSuggestion = ""
#endif
	
	var description: String {
		"\(.bold)no files were given as input\(.normal)\(windowsSuggestion)"
	}
}
