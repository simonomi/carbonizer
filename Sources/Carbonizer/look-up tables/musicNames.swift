// official names from music players: 108 109 110 112 113 323 324 325 326 327 328 331 332 333 925 928 929 930 932 934 935 936 937 938 939 1093 1296 1297 1303 1304

let musicNames: [Int32: String] = [
	1:    "opening ocean",
	2:    "vivosaur island",
	3:    "vivosaur island again?",
	4:    "fossil center",
	5:    "richmond building i think",
	6:    "mcjunkers",
	7:    "guild",
	8:    "vivosaur island again again?",
	9:    "fossil stadium",
	10:   "hotel",
	11:   "police station",
	12:   "greenhorn plains",
	13:   "knotwood forest",
	14:   "digadigamid",
	// 107: tutorial battle theme?
	108:  "Battle Theme",
	109:  "Level-Up Theme",
	110:  "Final Battle Theme",
//	111:  "", // battle theme for "normal enemies"
	112:  "Boss Battle Theme",
	113:  "Big Boss Theme",
	323:  "Scenario Theme 1", // post-level-up
	324:  "Scenario Theme 4 duplicate 1",
	325:  "Scenario Theme 5",
	326:  "Scenario Theme 2",
	327:  "Scenario Theme 3",
	328:  "Scenario Theme 4 duplicate 2",
	331:  "Rosie Theme",
	332:  "Duna Theme",
	333:  "BB Trio Theme",
	925:  "Duna Date",
	928:  "BB Occupation",
	929:  "Dynal Appearance",
	930:  "Pre-Guhnash",
	932:  "Diggins Theme",
	934:  "Chieftain Theme",
	935:  "McJunker Theme",
	936:  "Woolbeard Theme",
	937:  "Nick Nack Theme",
	938:  "Saurhead Theme",
	939:  "Idolcomp Theme",
	1093: "Warehouse Meeting",
	1296: "Rosie Date 1",
	1297: "Rosie Date 2",
	1303: "Bullwort Battle Theme",
	1304: "Dynal Battle Theme",
]

let musicIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: musicNames
		.mapValues { $0.lowercased() }
		.map { ($1, $0) }
)
