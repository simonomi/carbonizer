//
//  utilities.swift
//  
//
//  Created by simon pellerin on 2023-06-15.
//

import Foundation
#if os(Windows)
import WinSDK
#endif

extension FileManager {
	func contentsOfDirectory(at url: URL) throws -> [URL] {
		try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
	}
	
	enum FileType {
		case file, folder, other
	}
	
	static func type(of file: URL) throws -> FileAttributeType {
		(try FileManager.default.attributesOfItem(atPath: file.path)[.type] as? FileAttributeType) ?? .typeUnknown
	}
	
	static func getCreationDate(of file: URL) throws -> Date? {
		try FileManager.default.attributesOfItem(atPath: file.path)[.creationDate] as? Date
	}
	
	static func setCreationDate(of file: URL, to date: Date) throws {
#if os(macOS)
		try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: file.path)
#elseif os(Windows)
		let pathLength = file.path.count + 1
		let windowsFilePath = file.path.withCString(encodedAs: UTF16.self) {
			let buffer = UnsafeMutablePointer<UInt16>.allocate(capacity: pathLength)
			buffer.initialize(from: $0, count: pathLength)
			return UnsafePointer(buffer)
		}
		let hFile = CreateFileW(windowsFilePath, DWORD(GENERIC_WRITE), DWORD(FILE_SHARE_WRITE), nil, DWORD(OPEN_EXISTING), 0, nil)
		defer { CloseHandle(hFile) }
		var creationTime = FILETIME(from: time_t(date.timeIntervalSince1970))
		SetFileTime(hFile, &creationTime, nil, nil)
#endif
	}
}

extension Collection {
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	func element(at index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
}

extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.min { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		self.max { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func map<T>(_ transform: (Element) throws -> () -> T) rethrows -> [T] {
		try map(transform).map { $0() }
	}
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element {
		reduce(.zero, +)
	}
}

extension Collection where Index == Int {
	func chunked(into size: Int) -> [SubSequence] {
		stride(from: 0, to: count, by: size).map {
			self[$0 ..< Swift.min($0 + size, count)]
		}
	}
}

extension Collection where Element: Equatable {
	func isAllTheSame() -> Bool {
		allSatisfy { $0 == first }
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting) {
		self.init()
		outputFormatting = formatting
	}
}

extension BinaryInteger {
	func toNearestMultiple(of number: Self) -> Self {
		if isMultiple(of: number) {
			return self
		} else {
			return self + number - (self % number)
		}
	}
}

// for windows 🙄
extension URL {
	static var homeDirectory: URL {
		FileManager.default.homeDirectoryForCurrentUser
	}
}
