import SwiftSyntax

struct Attributes {
	var padding: ValueOrProperty?
	var offset: ValueOrProperty?
	var count: ValueOrProperty?
	var offsets: Property.Size.Offsets?
	var length: ValueOrProperty?
	var ifCondition: String?
	var endOffset: ValueOrProperty?
	var isStatic: Bool
	
	init(from attributes: AttributeListSyntax, isStatic: Bool) throws {
		self.isStatic = isStatic
		
		for attribute in attributes.compactMap(AttributeSyntax.init) {
			try parseAttribute(attribute)
		}
		
		if offset != nil && padding != nil {
			throw AttributeParsingError.paddingAndOffset
		}
	}
}
