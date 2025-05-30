import Foundation
import Testing

extension URL {
#if os(Linux)
	static let documentsDirectory = URL.homeDirectory.appending(component: "Documents")
#endif
	
	static let testFileDirectory: URL = .documentsDirectory
		.appending(component: "ff1")
		.appending(component: "carbonizer-test-files")
	
	static let compressionDirectory: URL = .testFileDirectory.appending(component: "compression")
	
	static let roundTripsDirectory: URL = .testFileDirectory.appending(component: "round trips")
	
#if IN_CI
	static let wholeROMPath: URL? = nil
#else
	static let wholeROMPath: URL? = URL(filePath: "/Users/simonomi/ff1/Fossil Fighters.nds")
#endif
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
