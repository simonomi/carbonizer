// TODO: should this extension be a requirement of FileSystemObject?
// PostProcessor has `fatalError("shouldnt be called on \(Self.self)")`
extension FileSystemObject {
	func setFile(at path: ArraySlice<String>, to content: any FileSystemObject) {
		fatalError()
	}
}

extension NDS.Unpacked {
	mutating func setFile(at path: ArraySlice<String>, to content: any FileSystemObject) {
		if let index = contents.firstIndex(where: { $0.name == path.dropFirst().first }) {
			contents[index].setFile(at: path.dropFirst(2), to: content)
		} else if path.dropFirst().first?.hasPrefix(".") != true {
			fatalError("not found: '\(path.dropFirst().first ?? "nil")'")
		}
	}
}

extension Folder {
	mutating func setFile(at path: ArraySlice<String>, to content: any FileSystemObject) {
		if let index = contents.firstIndex(where: { $0.name == path.first }) {
			if path.count == 1 {
				contents[index] = content
			} else {
				contents[index].setFile(at: path.dropFirst(), to: content)
			}
		} else if path.dropFirst().first?.hasPrefix(".") != true {
			fatalError("not found: '\(path.first ?? "nil")'")
		}
	}
}
