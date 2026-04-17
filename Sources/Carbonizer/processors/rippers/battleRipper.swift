func battleRipperF(
	_ dbs: inout DBS.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	if environment.battles == nil {
		environment.battles = [:]
	}
	
	let battleID = UInt32(path.last!)!
	
	let japanese = environment.text?["japanese"]
	
	func name(for nameID: Int32) -> String {
		japanese?[safely: Int(nameID)] ?? "fighter"
	}
	
	environment.battles![battleID] = Processor.Environment.Battle(
		enemyName: name(for: dbs.fighter2.name.id),
		enemyLevel: dbs.fighter2.level,
		enemyVivosaurs: dbs.fighter2.vivosaurs
			.map(\.id.id)
			.map { vivosaurNames[$0] ?? String($0) }
	)
}
