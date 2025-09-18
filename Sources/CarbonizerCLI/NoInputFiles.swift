import ANSICodes

struct NoInputFiles: Error, CustomStringConvertible {
	var description: String {
		"\(.bold)no files were specified as input\(.normal)"
	}
}
