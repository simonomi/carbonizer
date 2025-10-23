import Foundation

extension FileHandle: @retroactive TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}
