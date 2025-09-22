import BinaryParser

protocol FixedPoint: Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
	associatedtype Wrapped: FixedWidthInteger
	static var fractionBits: Int { get }
	
	var raw: Wrapped { get }
	init(raw: Wrapped)
}

extension FixedPoint {
	init(_ fixedPoint: Double) {
		self.init(raw: Wrapped(fixedPoint * Double(1 << Self.fractionBits)))
	}
	
	init(floatLiteral value: Double) {
		self.init(value)
	}
	
	init(integerLiteral value: Int) {
		self.init(Double(value))
	}
}

extension Double {
	init<FP: FixedPoint>(_ fixedPoint: FP) {
		self = Self(fixedPoint.raw) / Self(1 << FP.fractionBits)
	}
}

@BinaryConvertible
struct FixedPoint2012: FixedPoint {
	var raw: Int32
	
	static let fractionBits = 12
}

@BinaryConvertible
struct FixedPoint1616: FixedPoint {
	var raw: Int32
	
	static let fractionBits = 16
}

@BinaryConvertible
struct FixedPoint124: FixedPoint {
	var raw: Int32
	
	static let fractionBits = 4
}

@BinaryConvertible
struct FixedPoint88: FixedPoint {
	var raw: Int32
	
	static let fractionBits = 8
}
