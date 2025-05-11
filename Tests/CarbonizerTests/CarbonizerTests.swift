import Foundation
import Testing

extension URL {
	static let testFileDirectory: URL = .documentsDirectory
		.appending(component: "ff1")
		.appending(component: "carbonizer-test-files")
	
	static let compressionDirectory: URL = .testFileDirectory.appending(component: "compression")
	
	static let roundTripsDirectory: URL = .testFileDirectory.appending(component: "round trips")
}

extension Issue {
	struct Failure: Error {}
	
	static func failure(
		_ comment: Comment? = nil,
		sourceLocation: SourceLocation = #_sourceLocation
	) throws -> Never {
		record(comment, sourceLocation: sourceLocation)
		throw Failure()
	}
}
