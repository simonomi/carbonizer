import Foundation

extension URL {
	static let testFileDirectory: URL = .documentsDirectory
		.appending(component: "ff1")
		.appending(component: "carbonizer-test-files")
	
	static let compressionDirectory: URL = .testFileDirectory.appending(component: "compression")
}
