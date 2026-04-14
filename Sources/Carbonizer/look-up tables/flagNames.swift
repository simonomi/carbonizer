let ff1FlagNames: [UInt8: [UInt32: String]] = [
	8: [
		68: "case upgrade level",
	],
	9: [
		3: "money",
		4: "current mask",
		6: "profile background",
		7: "player variant",
		19: "donation points",
		30: "sonar monitor upgrade level",
		31: "sonar fossil chip upgrade level",
		32: "sonar fossil filter upgrade level",
	],
	10: [
		30: "multiplayer unlocked",
		33: "super drill unlocked",
		34: "hyper hammer unlocked",
	]
]

let ff1FlagIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: ff1FlagNames
		.flatMap { (type, idNames) in
			idNames.map { (id, name) in
				(
					name.lowercased(),
					Int32(id) | (Int32(type) << 24)
				)
			}
		}
)


let ffcFlagNames: [UInt8: [UInt32: String]] = [:]

let ffcFlagIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: ffcFlagNames
		.flatMap { (type, idNames) in
			idNames.map { (id, name) in
				(
					name.lowercased(),
					Int32(id) | (Int32(type) << 24)
				)
			}
		}
)
