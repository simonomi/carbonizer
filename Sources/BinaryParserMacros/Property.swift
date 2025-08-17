struct Property {
	var name: String
	var type: String
	var size: Size
	var isStatic: Bool
	var padding: ValueOrProperty?
	var offset: ValueOrProperty?
	var expected: String?
	var length: ValueOrProperty?
	var ifCondition: String?
	var endOffset: ValueOrProperty?
	var fourByteAlign: Bool
	
	enum Size {
		case auto
		case count(ValueOrProperty)
		case offsets(Offsets)
		
		enum Offsets {
			case givenByPath(String)
			case givenByPathAndSubpath(String, String)
			case givenByPathStartToEnd(String, String, String)
		}
	}
}
