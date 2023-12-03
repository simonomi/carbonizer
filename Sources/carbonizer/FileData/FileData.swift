//
//  FileData.swift
//
//
//  Created by alice on 2023-12-01.
//

import BinaryParser
import Foundation

protocol FileData {
	associatedtype Packed: BinaryConvertible, Writeable
	associatedtype Unpacked: Writeable = Self
	init(packed: Packed) throws
	init(unpacked: Unpacked) throws
	func toPacked() throws -> Packed
	func toUnpacked() throws -> Unpacked
	static var packedFileExtension: String { get }
	static var unpackedFileExtension: String { get }
}

extension FileData where Packed == Self {
	init(packed: Self) { self = packed }
	func toPacked() -> Self { self }
}

extension FileData where Unpacked == Self {
	init(unpacked: Self) { self = unpacked }
	func toUnpacked() -> Self { self }
}

extension FileData {
	init(packed bytes: Datastream) throws {
		// NOTE: add carbonizer state here
		self = try Self(packed: try bytes.read(Packed.self))
	}
}

extension FileData where Unpacked: Codable {
	init(unpacked bytes: Data) throws {
		// NOTE: add carbonizer state here
		self = try Self(unpacked: JSONDecoder().decode(Unpacked.self, from: bytes))
	}
}

protocol InitFrom<InitsFrom> {
	associatedtype InitsFrom
	init(_: InitsFrom)
}

extension FileData where Packed: InitFrom, Packed.InitsFrom == Self {
	func toPacked() -> Packed { Packed(self) }
}
