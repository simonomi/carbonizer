let regionNames: [Int32: String] = [
	12:  "entering relic hotel",
	41:  "entering fossil center",
	44:  "leaving fossil center",
	388: "entering main mine room",
	421: "greenhorn plains above gate area",
	796: "bottom right elevator in hotel",
]

let regionIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: regionNames
		.mapValues { $0.lowercased() }
		.map { ($1, $0) }
)
