@attached(extension, conformances: BinaryConvertible, names: named(init), named(write))
public macro BinaryConvertible() = #externalMacro(module: "BinaryParserMacros", type: "BinaryConvertibleMacro")

public enum Operator<T> {
	case plus(T)
	case minus(T)
	case times(T)
	case dividedBy(T)
	case modulo(T)
}

@attached(peer)
public macro Padding(bytes: Int) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offset(_ offset: Int) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offset<S, T: BinaryInteger>(givenBy offset: KeyPath<S, T>, _ operator: Operator<T>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offset<S, T: BinaryInteger>(givenBy offset: KeyPath<S, T>, _ operator: Operator<KeyPath<S, T>>...) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Count(_ count: Int) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Count<S, T: BinaryInteger>(givenBy count: KeyPath<S, T>, _ operator: Operator<T>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Count<S, T: BinaryInteger>(givenBy count: KeyPath<S, T>, _ operator: Operator<KeyPath<S, T>>...) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offsets<S, T: BinaryInteger>(givenBy offsets: KeyPath<S, [T]>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offsets<S, T, U: BinaryInteger>(givenBy offsets: KeyPath<S, [T]>, at subPath: KeyPath<T, U>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Offsets<S, T, U: BinaryInteger>(givenBy offsets: KeyPath<S, [T]>, from startPath: KeyPath<T, U>, to endPath: KeyPath<T, U>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Length(_ length: Int) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Length<S, T: BinaryInteger>(givenBy length: KeyPath<S, T>, _ operator: Operator<T>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro Length<S, T: BinaryInteger>(givenBy length: KeyPath<S, T>, _ operator: Operator<KeyPath<S, T>>...) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

public enum Comparison<T> {
	case equalTo(T)
	case notEqualTo(T)
	case greaterThan(T)
	case lessThan(T)
	case greaterThanOrEqualTo(T)
	case lessThanOrEqualTo(T)
}

@attached(peer)
public macro If<S, T>(_ property: KeyPath<S, T>, is: Comparison<T>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro EndOffset(_ offset: Int) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

@attached(peer)
public macro EndOffset<S, T: BinaryInteger>(givenBy offset: KeyPath<S, T>) = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")

/// Include a static property as if it were a non-static property
@attached(peer)
public macro Include() = #externalMacro(module: "BinaryParserMacros", type: "EmptyMacro")
