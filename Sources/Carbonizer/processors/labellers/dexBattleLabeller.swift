func dexBattleLabellerF(
	_ dex: inout DEX.Unpacked,
	at path: [String],
	in environment: inout Processor.Environment,
	configuration: Configuration
) throws {
	let battles = try environment.get(\.battles)
	
	dex.commands = dex.commands.map {
		$0.reduce(into: []) { partialResult, command in
			for battle in command.battles() {
				if let battleInfo = battles[battle] {
					partialResult.append(.comment(battleInfo.description))
				}
			}
			
			partialResult.append(command)
		}
	}
}

extension Processor.Environment.Battle: CustomStringConvertible {
	var description: String {
		let vivosaurs = switch enemyVivosaurs.count {
			case 2:
				"\(enemyVivosaurs[0]) and \(enemyVivosaurs[1])"
			case 3:
				"\(enemyVivosaurs[0]), \(enemyVivosaurs[1]), and \(enemyVivosaurs[2])"
			default:
				"\(enemyVivosaurs.joined(separator: ", "))"
		}
		
		return "level \(enemyLevel) \(enemyName) with \(vivosaurs)"
	}
}
