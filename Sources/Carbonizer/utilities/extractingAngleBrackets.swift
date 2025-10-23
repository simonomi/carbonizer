func extractAngleBrackets(from text: Substring) -> ([Substring], [String])? {
	let argumentStartIndices = text
		.indices(of: "<")
		.ranges
		.map(\.lowerBound)
	let argumentEndIndices = text
		.indices(of: ">")
		.ranges
		.map(\.upperBound)
	
	guard argumentStartIndices.count == argumentEndIndices.count else { return nil }
	
	let argumentRanges = zip(argumentStartIndices, argumentEndIndices)
		.map { $0..<$1 }
		.map(RangeSet.init)
		.reduce(into: RangeSet()) { $0.formUnion($1) }
	
	let arguments = argumentRanges.ranges
		.map { text[$0].dropFirst().dropLast() }
		.flatMap {
			if $0.contains(", ") {
				$0.split(separator: ", ")
			} else if $0.contains(",") {
				$0.split(separator: ",")
			} else {
				[$0]
			}
		}
	
	let textWithoutArguments = RangeSet(text.startIndex..<text.endIndex)
		.subtracting(argumentRanges)
		.ranges
		.map { text[$0] }
		.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
		.filter(\.isNotEmpty)
	
	return (arguments, textWithoutArguments)
}
