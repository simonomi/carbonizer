import Foundation

extension FileHandle: @retroactive TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}

extension TextOutputStream where Self == FileHandle {
	static var standardError: FileHandle {
		get { .standardError }
		set {}
	}
}
