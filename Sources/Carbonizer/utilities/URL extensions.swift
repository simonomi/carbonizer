import Foundation

#if os(Windows)
import WinSDK
#endif

extension URL {
#if os(Windows)
	func path(percentEncoded: Bool) -> String {
		path
	}
	
	func currentDirectory() -> URL {
		URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	}
	
	func appending(component: some StringProtocol) -> URL {
		appendingPathComponent(String(component))
	}
#endif
	
	func getModificationDate() throws -> Date? {
		try resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
	}
	
	func getCreationDate() throws -> Date? {
		try resourceValues(forKeys: [.creationDateKey]).creationDate
	}
	
	func setCreationDate(to date: Date) throws {
#if os(Windows)
		let pathLength = path.count + 1
		
		let windowsFilePath = path.withCString(encodedAs: UTF16.self) {
			let buffer = UnsafeMutablePointer<UInt16>.allocate(capacity: pathLength)
			buffer.initialize(from: $0, count: pathLength)
			return UnsafePointer(buffer)
		}
		
		let shareAll = DWORD(FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE)
		let hFile = CreateFileW(windowsFilePath, DWORD(GENERIC_WRITE), shareAll, nil, DWORD(OPEN_EXISTING), 0, nil)
		if hFile == INVALID_HANDLE_VALUE {
			throw WindowsError(code: GetLastError())
		}
		defer { CloseHandle(hFile) }
		
		var creationTime = FILETIME(from: time_t(date.timeIntervalSince1970))
		guard SetFileTime(hFile, &creationTime, nil, nil) else {
			throw WindowsError(code: GetLastError())
		}
#else
		try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: path(percentEncoded: false))
#endif
	}
	
	public func exists() -> Bool {
		var path = path(percentEncoded: false)
		
		// for some reason, fileExists doesn't work properly if the directory hint is wrong,
		// and there's no API to remove one :/
		if path.hasSuffix("/") {
			path.removeLast()
		}
		
		return FileManager.default.fileExists(atPath: path)
	}
	
	func contents() throws -> [URL] {
		try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
	}
	
	func isDirectory() throws -> Bool {
		try self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory!
	}
}
