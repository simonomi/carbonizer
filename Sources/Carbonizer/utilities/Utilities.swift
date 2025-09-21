#if os(Linux)
@preconcurrency import Glibc
#endif

import Foundation

#if os(Windows)
import WinSDK
#endif

func todo(
	_ message: String? = nil,
	function: String = #function,
	file: StaticString = #file,
	line: UInt = #line
) -> Never {
	if let message {
		fatalError("TODO: \(function): \(message)", file: file, line: line)
	} else {
		fatalError("TODO: \(function)", file: file, line: line)
	}
}

typealias Byte = UInt8

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

extension Collection {
	var isNotEmpty: Bool {
		!isEmpty
	}
	
	func max(by keyPath: KeyPath<Element, some Comparable>) -> Element? {
		self.max { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
	}
}

extension BinaryInteger {
	@inline(__always)
	var isEven: Bool {
		isMultiple(of: 2)
	}
	
	@inline(__always)
	var isOdd: Bool {
		!isMultiple(of: 2)
	}
}

extension Collection where Index: Strideable {
	public func chunked(maxSize: Index.Stride) -> [SubSequence] {
		stride(from: startIndex, to: endIndex, by: maxSize).map {
			self[$0..<Swift.min($0.advanced(by: maxSize), endIndex)]
		}
	}
	
	public func chunked(exactSize: Index.Stride) -> [SubSequence] {
		chunks(exactSize: exactSize, every: exactSize)
	}
	
// 	public func chunks(maxSize: Int, every: Int)
	
	public func chunks(
		exactSize: Index.Stride,
		every chunkInterval: Index.Stride
	) -> [SubSequence] {
		stride(
			from: startIndex,
			through: endIndex.advanced(by: -exactSize),
			by: chunkInterval
		).map {
			self[$0..<$0.advanced(by: exactSize)]
		}
	}
}

func zip<S: Sequence, T: Sequence, U: Sequence>(
	_ first: S,
	_ second: T,
	_ third: U
) -> [(S.Element, T.Element, U.Element)] {
	zip(first, zip(second, third))
		.map { ($0, $1.0, $1.1) }
}

func zip<S: Sequence, T: Sequence, U: Sequence, V: Sequence>(
	_ first: S,
	_ second: T,
	_ third: U,
	_ fourth: V
) -> [(S.Element, T.Element, U.Element, V.Element)] {
	zip(first, zip(second, zip(third, fourth)))
		.map { ($0, $1.0, $1.1.0, $1.1.1) }
}

func makeOffsets(
	start: UInt32,
	sizes: some Collection<UInt32>,
	alignedTo alignment: UInt32 = 1
) -> [UInt32] {
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

func splitFileName(_ name: String) -> (name: String, fileExtensions: String) {
	let split = name.split(separator: ".", maxSplits: 1)
	if split.count == 2 {
		return (String(split[0]), String(split[1]))
	} else {
		return (name, "")
	}
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
	
	init(withoutDecimalIfWhole number: some FloatingPoint & LosslessStringConvertible) {
		if number.truncatingRemainder(dividingBy: 1) == 0 {
			assert(String(number).suffix(2) == ".0")
			self = String(String(number).dropLast(2))
		} else {
			self = String(number)
		}
	}
}

extension Array where Element: Comparable {
	func isSorted() -> Bool {
		// this might be super slow idk
		for (first, second) in zip(self, self.dropFirst()) {
			guard first < second else { return false }
		}
		return true
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

// TODO: use subprocess package
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
		FileManager.default.fileExists(atPath: path(percentEncoded: false))
	}
	
	func contents() throws -> [URL] {
		try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil)
	}
	
	func isDirectory() throws -> Bool {
		try self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory!
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

extension JSONEncoder {
	convenience init(_ formatting: OutputFormatting...) {
		self.init()
		outputFormatting = OutputFormatting(formatting)
	}
}

extension JSONDecoder {
	convenience init(allowsJSON5: Bool) {
		self.init()
		self.allowsJSON5 = allowsJSON5
	}
}

extension FileHandle: @retroactive TextOutputStream {
	public func write(_ string: String) {
		write(Data(string.utf8))
	}
}

func waitForInput() {
	print("Press Enter to continue...", terminator: "")
	let _ = readLine()
}

func extractAngleBrackets(from text: Substring) -> ([Substring], [String])? {
	let argumentStartIndices = text
		.indices(of: "<")
		.ranges
		.map(\.lowerBound)
	let argumentEndIndices = text
		.indices(of: ">")
		.ranges
		.map(\.upperBound)
	
	guard argumentStartIndices.count == argumentEndIndices.count else { return nil }
	
	let argumentRanges = zip(argumentStartIndices, argumentEndIndices)
		.map { $0..<$1 }
		.map(RangeSet.init)
		.reduce(into: RangeSet()) { $0.formUnion($1) }
	
	let arguments = argumentRanges.ranges
		.map { text[$0].dropFirst().dropLast() }
		.flatMap {
			if $0.contains(", ") {
				$0.split(separator: ", ")
			} else if $0.contains(",") {
				$0.split(separator: ",")
			} else {
				[$0]
			}
		}
	
	let textWithoutArguments = RangeSet(text.startIndex..<text.endIndex)
		.subtracting(argumentRanges)
		.ranges
		.map { text[$0] }
		.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
		.filter(\.isNotEmpty)
	
	return (arguments, textWithoutArguments)
}

extension Collection where Element: Equatable {
	func areAllTheSame() -> Bool {
		allSatisfy { $0 == first }
	}
	
	func commonPrefix(with other: some Collection<Element>) -> SubSequence {
		zip(indices, other.indices)
			.first { self[$0] != other[$1] }
			.map(\.0)
			.map { self[..<$0] } ?? self[..<Swift.min(endIndex, index(startIndex, offsetBy: other.count))]
	}
}

extension Collection<Byte> {
	func firstRunIndices(minCount: Int) -> Range<Index>? {
		for index in indices.dropLast(minCount) {
			let window = self[index..<self.index(index, offsetBy: minCount)]
			if window.areAllTheSame() {
				let endOfRun = self[index...].firstIndex { $0 != self[index] } ?? endIndex
				
				return index..<endOfRun
			}
		}
		
		return nil
	}
}

extension Date {
	var timeElapsed: TimeInterval {
		-timeIntervalSinceNow
	}
}

extension Sequence {
	func interspersed(with element: Element) -> JoinedSequence<[[Element]]> {
		map { [$0] }.joined(separator: [element])
	}
}

extension Set {
	consuming func inserting(_ element: Element) -> Self {
		insert(element)
		return self
	}
}

extension Double {
	init(fixedPoint: some BinaryInteger, fractionBits: Int = 12) {
		self = Self(fixedPoint) / Self(1 << fractionBits)
	}
}

extension BinaryInteger {
	init(fixedPoint: Double, fractionBits: Int = 12) {
		self = Self(fixedPoint * Double(1 << fractionBits))
	}
}

extension DefaultStringInterpolation {
	mutating func appendInterpolation(_ number: some BinaryInteger, digits: Int) {
		precondition(number >= 0)
		appendInterpolation(String(number).padded(toLength: digits, with: "0"))
	}
}
