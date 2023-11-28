//
//  BinaryConvertible.swift
//
//
//  Created by alice on 2023-11-12.
//

import Foundation

public protocol BinaryConvertible {
	init(_ data: Datastream) throws
}

extension String: BinaryConvertible {
	public init(_ data: Datastream) throws {
		self = try data.read(String.self)
	}
}

extension Data: BinaryConvertible {
	public init(_ data: Datastream) throws {
		self = try data.read(Data.self)
	}
}
