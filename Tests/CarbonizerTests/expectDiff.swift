import Foundation
import Testing

func expectUnchanged<Bytes: Collection<UInt8> & Equatable>(
	from expected: Bytes,
	to actual: Bytes,
	name: String,
	sourceLocation: SourceLocation = #_sourceLocation
) throws {
	guard actual != expected else { return }
	
	let expectedPath = URL.temporaryDirectory
		.appending(component: "\(name) expected")
		.appendingPathExtension("bin")
	
	let actualPath = URL.temporaryDirectory
		.appending(component: "\(name) actual")
		.appendingPathExtension("bin")
	
	try Data(expected).write(to: expectedPath)
	try Data(actual).write(to: actualPath)
	
	Issue.record("nvim -d \"\(expectedPath.path(percentEncoded: false))\" \"\(actualPath.path(percentEncoded: false))\"", sourceLocation: sourceLocation)
}
