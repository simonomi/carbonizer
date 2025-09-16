let movementNames: [Int32: String] = [
	1: "jump",
	2: "spin",
	3: "big spin",
	4: "fall front",
	5: "stand up from front",
	6: "fall through hole",
	7: "land from hole",
	8: "shake",
	9: "squish",
	10: "ascend",
	11: "descend",
	12: "jump and squish",
	13: "teleport",
	14: "shrink",
	15: "grow bigger",
	16: "lay front",
	17: "small",
	18: "sideways",
	19: "righten from sideways",
	20: "fall back",
	21: "lay back",
	22: "stand up from back",
	23: "fall down sideways",
]

let movementIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: movementNames
		.mapValues { $0.lowercased() }
		.map { ($1, $0) }
)
