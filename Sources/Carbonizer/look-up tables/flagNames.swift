let ff1FlagNames: [UInt8: [UInt32: String]] = [
	0: [
		58: "shop dialogue result 0",
		60: "buy today's special or exchange DP dialogue result 0",
		69: "tool upgrade dialogue results 0",
		80: "give Nick Nack dropping fossils dialogue result 0",
		256: "Greenhorn Plains pay-to-dig dialogue result 0",
		257: "Rivet Ravine pay-to-dig dialogue result 0",
	],
	5: [
		111: "fossil chip is level 0",
		112: "fossil chip is level 1",
		113: "fossil chip is level 2",
		// <211 5> is set to true when wendy says "welcome to the fossil center"
		// - "told to check in"?
		// - "visited fossil center"?
		// - "opening cutscene played"?
		// <207 5> - "checked in at hotel" (when dropped off in room, not when leaving)
		// <212 5> - set during diggins' cleaning tutorial
		// <223 5> - set when battling travers (set to false if you lose)
		// <260 5> - is asking diggins questions (end of cleaning tut or if u come back)
		1008: "has given Nick Nack the sandal fossil",
		4031: "pay-to-dig area purchased",
		5503: "talking to Greenhorn Plains pay-to-dig attendent",
//		8007: "BB invasion", // ?
		8045: "sonar monitor upgrade 1 unlocked",
		8046: "sonar monitor upgrade 2 unlocked",
		8047: "sonar fossil filter 1 unlocked",
		8048: "sonar fossil filter 2 unlocked",
		8049: "sonar fossil chip 1 unlocked",
		8050: "sonar fossil chip 2 unlocked",
		8051: "Super Drill unlocked 5", // not sure how different from the 10 version
		8052: "Hyper Hammer unlocked 5", // not sure how different from the 10 version
		8058: "asking which tool upgrade",
		9037: "talking to Rivet Ravine pay-to-dig attendent",
		11006: "shop has Dino Cakes",
		11016: "chose to sell items at shop",
		11150: "talking to Nick Nack",
		11151: "Nick Nack asking for dropping fossils",
		11152: "gave Nick Nack dropping fossils",
		11153: "getting a reward from Nick Nack",
		11501: "has Oasis Seed 1",
		11502: "has Oasis Seed 2",
		11503: "has Oasis Seed 3",
		11504: "has Oasis Seed 4",
		11505: "oasis 1 grown",
		11506: "oasis 2 grown",
		11507: "oasis 3 grown",
		11508: "oasis 4 grown",
		11509: "oasis quest complete",
		11510: "shop has an Oasis Seed",
		11511: "player is in Parchment Desert",
		11711: "shop has Snowberries",
	],
	8: [
		56: "chapter number",
		58: "shop dialogue result",
		// <59 8> might be mask shop result? or maybe previous mask?
		// <59 8> is used to read a dialogue choice (temp variable?)
		60: "buy today's special or exchange DP dialogue result",
		62: "sonar upgrade digitmask", // sum of 63-65
		63: "sonar monitor upgrade digitmask", // default 100, upgarded 200, max 0 ?????
		64: "sonar fossil filter digitmask", // default 10, upgarded 20, max 0 ?????
		65: "sonar fossil chip digitmask", // default 1, upgarded 2, max 0 ?????
		67: "cleaning upgrades left bitmsk", // both left: 3, drill left: 2, hammer left: 1, none left: 0
		                                     // aka hammer is bit 0, drill is bit 1 this is upgrades left
		68: "case upgrade level", // 1:8, 2:16, 3:24, 4:32, 5:48, 0:64
		69: "tool upgrade dialogue results",
		77: "left over dropping fossils",
		78: "dropping fossils given to Nick Nack",
		80: "give Nick Nack dropping fossils dialogue result",
		256: "Greenhorn Plains pay-to-dig dialogue result",
		257: "Rivet Ravine pay-to-dig dialogue result",
		342: "sellable items",
	],
	9: [
		2: "case size in pages", // 1:8, 2:16, 3:24, 4:32, 6:48, 8:64
		3: "money",
		4: "current mask",
		6: "profile background", // red/blue/yellow
		7: "player variant",
		8: "fossil rocks",
		9: "colored fossil rocks",
		// 10: dark fossil rocks ?
		11: "jewels",
		12: "dropping fossils",
		14: "fossils just integrated by KL-33N",
		15: "fossils just donated by KL-33N",
		17: "points on fossil just cleaned",
		18: "points of a previously-cleaned fossil",
		19: "donation points",
		20: "fossil rocks dropped off for cleaning",
		21: "KL-33N level",
		22: "KL-33N max cleaning score",
		23: "cleanings until KL-33N levels up",
		24: "fossils in storage",
		25: "successful cleanings",
		26: "oasis growth timer",
		28: "gems cleaned by KL-33N",
		29: "value of gems just sold by KL-33N",
		30: "sonar monitor upgrade level", // 2 is 800 G, 3 is 3500 G
		31: "sonar fossil chip upgrade level", // 2 is 10000 G, 3 is 35000 G
		32: "sonar fossil filter upgrade level", // 2 is 5000 G, 3 is 8000 G
		39: "cleaning time bonus",
//		41: something that can be sold in the shop (possibly beta?)
		46: "donation points just added",
	],
	10: [
		4:  "case is full",
		28: "status menu unlocked",
		30: "multiplayer unlocked",
//		31: "tool upgrades available", // maybe to do with the shop dialogue ?
		32: "Dino Medal screen unlocked",
		33: "Super Drill unlocked",
		34: "Hyper Hammer unlocked",
		41: "shop is sold out",
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
