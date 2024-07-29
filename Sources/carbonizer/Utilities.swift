import Foundation

#if os(Windows)
import WinSDK
#endif

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

func identity<T>(_ value: T) -> T { value }

/// pipe operator
//func |> <T, U>(lhs: T, rhs: (T) throws -> U) rethrows -> U {
//	try rhs(lhs)
//}

func createOffsets(start: UInt32, sizes: [UInt32], alignedTo alignment: UInt32 = 1) -> [UInt32] {
	if sizes.isEmpty {
		[]
	} else {
		sizes
			.dropLast()
			.reduce(into: [start]) { offsets, size in
				offsets.append((offsets.last! + size).roundedUpToTheNearest(alignment))
			}
	}
}

func hex<T: BinaryInteger & SignedNumeric>(_ value: T) -> String {
	if value < 0 {
		"-0x\(String(-value, radix: 16))"
	} else {
		"0x\(String(value, radix: 16))"
	}
}

func logProgress(_ items: Any...) {
	let message = items
		.map { String(describing: $0) }
		.joined(separator: " ")
	
	print(String(repeating: " ", count: 100), terminator: "\r")
	print(message, terminator: "\r")
	
	fflush(stdout)
}

func splitFileName(_ name: String) -> (name: String, fileExtension: String) {
	let split = name.split(separator: ".", maxSplits: 1)
	if split.count == 2 {
		return (String(split[0]), String(split[1]))
	} else {
		return (name, "")
	}
}

func combineFileName(_ name: String, withExtension fileExtension: String) -> String {
	URL(filePath: name).appendingPathExtension(fileExtension).lastPathComponent
}

extension Array {
	subscript(x x: Index, y y: Index, width width: Index) -> Element {
		get { self[x + y * width] }
		set { self[x + y * width] = newValue }
	}
	
	subscript(safely index: Index) -> Element? {
		if indices.contains(index) {
			self[index]
		} else {
			nil
		}
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

extension StringProtocol {
	func caseInsensitiveEquals(_ other: some StringProtocol) -> Bool {
		caseInsensitiveCompare(other) == .orderedSame
	}
}

// TODO: remove bc this is slow
extension Array where Element: Comparable {
	func isSorted() -> Bool {
		self == self.sorted()
	}
}

struct WindowsError: Error {
	var code: UInt32
}

extension Optional {
	func orElseThrow(_ error: @autoclosure () -> some Error) throws -> Wrapped {
		if let self {
			self
		} else {
			throw error()
		}
	}
}

@discardableResult
func shell(_ command: String) throws -> String {
	let task = Process()
	let pipe = Pipe()
	
	task.standardOutput = pipe
	task.standardError = pipe
	task.arguments = ["-c", command]
	task.executableURL = URL(fileURLWithPath: "/bin/zsh")
	task.standardInput = nil
	
	try task.run()
	
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!
	
	return output
}

extension URL {
#if os(Windows)
	func path(percentEncoded: Bool) -> String {
		path
	}
#endif
	
	func getModificationDate() throws -> Date? {
		try FileManager.default.attributesOfItem(atPath: path(percentEncoded: false))[.modificationDate] as? Date
	}
	
	func getCreationDate() throws -> Date? {
		try FileManager.default.attributesOfItem(atPath: path(percentEncoded: false))[.creationDate] as? Date
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
	
	func exists() -> Bool {
		FileManager.default.fileExists(atPath: path(percentEncoded: false))
	}
	
	func contents() throws -> [URL] {
		try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
	}
	
	enum FileType: Equatable {
		case file, folder, other(FileAttributeType?)
	}
	
	func type() throws -> FileType {
		let type = try FileManager.default.attributesOfItem(atPath: self.path(percentEncoded: false))[.type] as? FileAttributeType
		return switch type {
			case .some(.typeRegular): .file
			case .some(.typeDirectory): .folder
			default: .other(type)
		}
	}
	
#if os(Windows)
	func currentDirectory() -> URL {
		URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
	}
	
	func appending(component: some StringProtocol) -> URL {
		appendingPathComponent(String(component))
	}
#endif
}

// backporting from swift 6 standard library
// ideally remove once minimum macOS version is > 14
extension Substring {
	func myIndices(
		where predicate: (Element) throws -> Bool
	) rethrows -> [Range<Index>] {
		var result: [Range<Index>] = []
		var end = startIndex
		while let begin = try self[end...].firstIndex(where: predicate) {
			end = try self[begin...].prefix(while: predicate).endIndex
			result.append(begin ..< end)
			
			guard end < self.endIndex else {
				break
			}
			self.formIndex(after: &end)
		}
		
		return result
	}
	
	func myIndices(of element: Element) -> [Range<Index>] {
		myIndices(where: { $0 == element })
	}
}

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting...) {
		self.init()
		outputFormatting = OutputFormatting(formatting)
	}
}

#if compiler(>=6)
extension FileHandle: @retroactive TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}
#else
extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}
#endif

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
	
	mutating func appendInterpolation(_ number: some BinaryInteger, digits: Int) {
		precondition(number >= 0)
		appendInterpolation(String(number).padded(toLength: digits, with: "0"))
	}
}

func waitForInput() {
#if os(Windows)
	print("Press Enter to continue...", terminator: "")
	let _ = readLine()
#endif
}
