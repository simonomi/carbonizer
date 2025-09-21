struct UnsupportedFileTypes: Error, CustomStringConvertible {
	var fileTypes: [String]
	
	var description: String {
		if fileTypes.count == 1 {
			"unsupported file type: \(.red)\(fileTypes.first!)\(.normal)"
		} else {
			"unsupported file types: \(fileTypes.map { "\(.red)\($0)\(.normal)" }.joined(separator: ", "))"
		}
	}
}
