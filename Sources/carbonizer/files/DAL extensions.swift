extension DAL.Binary.Attack.SecondaryEffect {
	enum Effect: UInt8 {
		case nothing = 1, transformation, allZoneAttack, stealLPEqualToDamage, stealFP, spiteBlast, powerScale, knockToEZ, unused1, healWholeTeam, sacrifice, lawOfTheJungle, healOneAlly, unused2, cureAllStatuses, swapZones
	}
	
	var effect: Effect {
		Effect(rawValue: effectCode) ?? .nothing
	}
}

extension DAL.Binary.Attack.PrimaryEffect {
	enum Effect: UInt8 {
		case nothing = 1, poison, sleep, scare, excite, confusion, enrage, counter, enflame, harden, quicken
	}
	
	var effect: Effect {
		Effect(rawValue: effectCode) ?? .nothing
	}
}
