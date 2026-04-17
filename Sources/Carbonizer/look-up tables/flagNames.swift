let ff1FlagNames: [UInt8: [UInt32: String]] = [
	0: [
		80: "give Nick Nack dropping fossils dialogue result 0",
		256: "Greenhorn Plains pay-to-dig dialogue result 0",
		257: "Rivet Ravine pay-to-dig dialogue result 0",
	],
	5: [
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
		9037: "talking to Rivet Ravine pay-to-dig attendent",
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
	],
	8: [
		56: "chapter number",
		// <59 8> might be mask shop result? or maybe previous mask?
		// <59 8> is used to read a dialogue choice (temp variable?)
		// <62 8> number of sonar upgrades left..?
		// - or bitmask or smthn
		// - 1/2/10/20/100/200
		// - a base 10 bitmask lmao??
		// <67 8> number of cleaning upgrades left
		// - or maybe like a bitmask or smthn? buying the drill subtracts 2
		68: "case upgrade level", // (1:8, 2:16, 3:24, 4:32, 5:48)
		77: "left over dropping fossils",
		78: "dropping fossils given to Nick Nack",
		80: "give Nick Nack dropping fossils dialogue result",
		256: "Greenhorn Plains pay-to-dig dialogue result",
		257: "Rivet Ravine pay-to-dig dialogue result",
	],
	9: [
		// <2 9> == 1 means your case is size 8
		3: "money",
		4: "current mask",
		6: "profile background", // (red/blue/yellow)
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
		30: "sonar monitor upgrade level", // (2 is 800 G, 3 is 3500 G)
		31: "sonar fossil chip upgrade level", // (2 is 10000 G, 3 is 35000 G)
		32: "sonar fossil filter upgrade level", // (2 is 5000 G, 3 is 8000 G)
		39: "cleaning time bonus",
//		41: something that can be sold in the shop (possibly beta?)
		46: "donation points just added",
	],
	10: [
		28: "status menu unlocked",
		30: "multiplayer unlocked",
		32: "Dino Medal screen unlocked",
		33: "Super Drill unlocked",
		34: "Hyper Hammer unlocked",
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
