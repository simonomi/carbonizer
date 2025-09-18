import Foundation

extension URL {
#if os(Windows)
	init(filePath: String) {
		self.init(fileURLWithPath: filePath)
	}
#endif
	
	@Sendable
	static func fromFilePath(_ filePath: String) -> URL {
		URL(filePath: filePath)
	}
}
