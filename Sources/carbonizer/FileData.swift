//
//  FileData.swift
//
//
//  Created by alice on 2023-12-01.
//

import BinaryParser
import Foundation

protocol FileData {
	associatedtype Packed: BinaryConvertible
	associatedtype Unpacked = Self
	init(packed: Packed) throws
	init(unpacked: Unpacked) throws
	func toPacked() -> Packed
	func toUnpacked() -> Unpacked
}

extension FileData where Unpacked == Self {
	init(unpacked: Self) { self = unpacked }
	func toUnpacked() -> Self { self }
}

extension FileData {
	init(packed bytes: Datastream) throws {
		self = try Self(packed: try bytes.read(Packed.self))
	}
}

extension FileData where Unpacked: Codable {
	init(unpacked bytes: Data) throws {
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
