import Foundation

#if os(Windows)
import WinSDK
#endif

extension URL {
	static func fromFilePath(_ filePath: String) -> URL {
#if os(Windows)
		URL(fileURLWithPath: filePath)
#else
		URL(filePath: filePath)
#endif
	}
}

func identity<T>(_ value: T) -> T { value }

/// pipe operator
//func |> <T, U>(lhs: T, rhs: (T) throws -> U) rethrows -> U {
//	try rhs(lhs)
//}

func createOffsets(start: UInt32, sizes: [UInt32], alignedTo alignment: UInt32 = 1) -> [UInt32] {
	sizes
		.dropLast()
		.reduce(into: [start]) { offsets, size in
			offsets.append((offsets.last! + size).roundedUpToTheNearest(alignment))
		}
}

func hex(_ value: some BinaryInteger) -> String {
	String(value, radix: 16)
}

extension Array {
	subscript(x x: Index, y y: Index, width width: Index) -> Element {
		get { self[x + y * width] }
		set { self[x + y * width] = newValue }
	}
}

extension BinaryInteger {
	func roundedUpToTheNearest(_ value: Self) -> Self {
		if isMultiple(of: value) {
			self
		} else {
			self + (value - self % value)
		}
	}
}

extension Range where Bound: AdditiveArithmetic {
	init(start: Bound, count: Bound) {
		self = start..<(start + count)
	}
}

extension Sequence where Element: Sequence {
	func recursiveMap<T>(_ transform: @escaping (Element.Element) throws -> T) rethrows -> [[T]] {
		try map { try $0.map(transform) }
	}
}

extension Sequence where Element: AdditiveArithmetic {
	func sum() -> Element {
		reduce(.zero, +)
	}
}

extension Sequence {
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
		sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
	
	func compactMap<T>(as type: T.Type) -> [T] {
		compactMap { $0 as? T }
	}
}

extension Sequence where Element: Hashable {
	func uniqued() -> [Element] {
		Array(Set(self))
	}
}

extension String {
	enum Direction {
		case leading, trailing
	}
	
	func padded(
		toLength targetLength: Int,
		with character: Character,
		from direction: Direction = .leading
	) -> Self {
		guard targetLength > count else { return self }
		let padding = String(repeating: character, count: targetLength - count)
		return switch direction {
			case .leading: padding + self
			case .trailing: self + padding
		}
	}
}

extension URL {
	func getCreationDate() throws -> Date? {
		try FileManager.default.attributesOfItem(atPath: path)[.creationDate] as? Date
	}
	
	func setCreationDate(to date: Date) throws {
#if os(Windows)
		// try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: path)
		let pathLength = path.count + 1
		let windowsFilePath = path.withCString(encodedAs: UTF16.self) {
			let buffer = UnsafeMutablePointer<UInt16>.allocate(capacity: pathLength)
			buffer.initialize(from: $0, count: pathLength)
			return UnsafePointer(buffer)
		}
		let hFile = CreateFileW(windowsFilePath, DWORD(GENERIC_WRITE), DWORD(FILE_SHARE_WRITE), nil, DWORD(OPEN_EXISTING), 0, nil)
		defer { CloseHandle(hFile) }
		var creationTime = FILETIME(from: time_t(date.timeIntervalSince1970))
		SetFileTime(hFile, &creationTime, nil, nil)
#else
		try FileManager.default.setAttributes([.creationDate: date], ofItemAtPath: path(percentEncoded: false))
#endif
	}
	
	func contents() throws -> [URL] {
		try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
	}
	
	enum FileType {
		case file, folder, other(FileAttributeType?)
	}
	
	func type() throws -> FileType {
#if os(Windows)
		let type = try FileManager.default.attributesOfItem(atPath: self.path)[.type] as? FileAttributeType
#else
		let type = try FileManager.default.attributesOfItem(atPath: self.path(percentEncoded: false))[.type] as? FileAttributeType
#endif
		return switch type {
			case .some(.typeRegular): .file
			case .some(.typeDirectory): .folder
			default: .other(type)
		}
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting...) {
		self.init()
		outputFormatting = OutputFormatting(formatting)
	}
}

extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}

enum ANSIFontEffect: Int {
	case normal = 0
	case bold = 1
	case underline = 4
	case black = 30
	case red = 31
	case green = 32
	case yellow = 33
	case blue = 34
	case magenta = 35
	case cyan = 36
	case white = 37
	case blackBackground = 40
	case redBackground = 41
	case greenBackground = 42
	case yellowBackground = 43
	case blueBackground = 44
	case magentaBackground = 45
	case cyanBackground = 46
	case whiteBackground = 47
	case brightBlack = 90
	case brightRed = 91
	case brightGreen = 92
	case brightYellow = 93
	case brightBlue = 94
	case brightMagenta = 95
	case brightCyan = 96
	case brightWhite = 97
	case brightBlackBackground = 100
	case brightRedBackground = 101
	case brightGreenBackground = 102
	case brightYellowBackground = 103
	case brightBlueBackground = 104
	case brightMagentaBackground = 105
	case brightCyanBackground = 106
	case brightWhiteBackground = 107
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ fontEffects: ANSIFontEffect...) {
		let effects = fontEffects
			.map(\.rawValue)
			.map(String.init)
			.joined(separator: ";")
		appendInterpolation("\u{001B}[\(effects)m")
	}
}

func waitForInput() {
	print("Press Enter to continue...", terminator: "")
	let _ = readLine()
}
