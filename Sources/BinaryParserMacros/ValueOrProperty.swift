//
//  PossiblyGivenBy.swift
//
//
//  Created by alice on 2023-11-12.
//

enum ValueOrProperty {
	case value(Int)
	case property(String)
}

extension ValueOrProperty: ExpressibleByStringLiteral {
	init(stringLiteral value: StringLiteralType) {
		self = .property(value)
	}
}

extension ValueOrProperty: ExpressibleByIntegerLiteral {
	init(integerLiteral value: IntegerLiteralType) {
		self = .value(value)
	}
	
	var value: String {
		switch self {
			case .value(let value): String(value)
			case .property(let property): property
		}
	}
}
