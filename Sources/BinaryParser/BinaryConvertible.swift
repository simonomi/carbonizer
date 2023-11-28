//
//  BinaryConvertible.swift
//
//
//  Created by alice on 2023-11-12.
//

import Foundation

public protocol BinaryConvertible {
	init(_ data: Datastream) throws
	func write(to data: Datawriter)
}

extension Datastream {
	public func write(to data: Datawriter) {
		data.write(self)
	}
}

extension String: BinaryConvertible {
	public init(_ data: Datastream) throws {
		self = try data.read(String.self)
	}
	
	public func write(to data: Datawriter) {
		data.write(self)
	}
}
