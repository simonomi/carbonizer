let effectNames: [Int32: String] = [
	1: "ugh",                      // ase
	2: "exclamation point",        // bikkuri
	3: "light bulb left",          // denkyuu
	4: "haha",                     // warai
	5: "three white lines left",   // ase2
	6: "grrr",                     // ikari
	7: "three red lines",          // kiduki
	8: "question mark left",       // hatena
	9: "thinking",                 // gusyagusya
	10: "heart left",              // heart
	11: "dizzy",                   // kurukuru
	12: "wha left/right",          // gangan
	13: "ellipses left",           // mugon
	14: "three white lines right", // ase2_2
	15: "question mark right",     // hatena2
	16: "crying",                  // nakimusi
	17: "wha in/out",              // gagagangan
	18: "firework middle",         // hanabi
	19: "firework left",           // hanabi_02
	20: "firework midleft",        // hanabi_03
	21: "heart right",             // heart2
	22: "ellipses right",          // mugon2
	23: "light bulb right"         // denkyuu2
]

let effectIDs: [String: Int32] = Dictionary(
	uniqueKeysWithValues: effectNames
		.mapValues { $0.lowercased() }
		.map { ($1, $0) }
)
