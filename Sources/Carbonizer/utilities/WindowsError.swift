import Foundation

struct WindowsError: Error, CustomStringConvertible {
	var code: UInt32
	var context: StaticString
	var path: URL
	
	var description: String {
		"got error code \(.red)\(code)\(.normal) while \(context) for \(path)"
	}
}
