func dbsNameLabellerF(
	_ dbs: inout DBS.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let text = try environment.get(\.text)
	
	if var fighter1 = dbs.fighter1 {
		fighter1.name._label = text[safely: Int(fighter1.name.id)]
		dbs.fighter1 = fighter1
	}
	
	dbs.fighter2.name._label = text[safely: Int(dbs.fighter2.name.id)]
}
