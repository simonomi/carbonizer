//
//  File.swift
//  
//
//  Created by alice on 2023-11-19.
//

import SwiftSyntax

struct Attributes {
	var padding: ValueOrProperty?
	var offset: ValueOrProperty?
	var count: ValueOrProperty?
	var offsets: Property.Size.Offsets?
	var length: ValueOrProperty?
	var ifCondition: String?
	var endOffset: ValueOrProperty?
	
	init(from attributes: AttributeListSyntax) throws {
		for attribute in attributes.compactMap(AttributeSyntax.init) {
			try parseAttribute(attribute)
		}
		
		if offset != nil && padding != nil {
			throw AttributeParsingError.paddingAndOffset
		}
	}
}
